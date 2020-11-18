# frozen_string_literal: true

module Subscriptions
  class CreateService
    attr_reader :current_user, :customer_params, :subscription_params

    def initialize(current_user, group:, customer_params:, subscription_params:)
      @current_user = current_user
      @group = group
      @customer_params = customer_params
      @subscription_params = subscription_params
    end

    def execute
      response = client.create_customer(create_customer_params)

      return response unless response[:success]

      # We can't use an email from GL.com because it may differ from the billing email.
      # Instead we use the email received from the CustomersDot as a billing email.
      customer_data = response.with_indifferent_access[:data][:customer]
      billing_email = customer_data[:email]
      token = customer_data[:authentication_token]

      client.create_subscription(create_subscription_params, billing_email, token)
    end

    private

    def create_customer_params
      {
        provider: 'gitlab',
        uid: current_user.id,
        credentials: credentials_attrs,
        customer: customer_attrs,
        info: info_attrs
      }
    end

    # Return an empty hash for now, because the Customers API requires the credentials attribute to be present,
    # although it does not require the actual values. Remove this once the Customers API has been updated.
    def credentials_attrs
      {}
    end

    def customer_attrs
      {
        country: country_code(customer_params[:country]),
        address_1: customer_params[:address_1],
        address_2: customer_params[:address_2],
        city: customer_params[:city],
        state: customer_params[:state],
        zip_code: customer_params[:zip_code],
        company: customer_params[:company]
      }
    end

    def info_attrs
      {
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        email: current_user.email
      }
    end

    def create_subscription_params
      {
        plan_id: subscription_params[:plan_id],
        payment_method_id: subscription_params[:payment_method_id],
        products: {
          main: {
            quantity: subscription_params[:quantity]
          }
        },
        gl_namespace_id: @group.id,
        gl_namespace_name: @group.name,
        preview: 'false'
      }
    end

    def country_code(country)
      World.alpha3_from_alpha2(country)
    end

    def client
      Gitlab::SubscriptionPortal::Client
    end
  end
end
