# frozen_string_literal: true

module API
  class Scim < ::API::Base
    include ::Gitlab::Utils::StrongMemoize

    feature_category :authentication_and_authorization

    prefix 'api/scim'
    version 'v2'
    content_type :json, 'application/scim+json'
    USER_ID_REQUIREMENTS = { id: /.+/ }.freeze

    namespace 'groups/:group' do
      params do
        requires :group, type: String
      end

      helpers ::EE::API::Helpers::ScimPagination

      helpers do
        def logger
          API.logger
        end

        def render_scim_error(error_class, message)
          error!({ with: error_class }.merge(detail: message), error_class::STATUS)
        end

        def scim_not_found!(message:)
          render_scim_error(::EE::API::Entities::Scim::NotFound, message)
        end

        def scim_error!(message:)
          render_scim_error(::EE::API::Entities::Scim::Error, message)
        end

        def scim_conflict!(message:)
          render_scim_error(::EE::API::Entities::Scim::Conflict, message)
        end

        def check_access_to_group!(group)
          token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)

          unauthorized! unless token && ScimOauthAccessToken.token_matches_for_group?(token, group)
        end

        def sanitize_request_parameters(parameters)
          filter = ActiveSupport::ParameterFilter.new(::Rails.application.config.filter_parameters)
          filter.filter(parameters)
        end

        # Instance variable `@group` is necessary for the
        # Gitlab::ApplicationContext in API::API
        def find_and_authenticate_group!(group_path)
          @group = find_group(group_path)

          scim_not_found!(message: "Group #{group_path} not found") unless @group
          scim_not_found!(message: "Group #{group_path} does not have SAML SSO configured") unless @group.saml_provider

          check_access_to_group!(@group)

          @group
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def update_scim_user(identity)
          parser = ::EE::Gitlab::Scim::ParamsParser.new(params)
          parsed_hash = parser.update_params

          if parser.deprovision_user?
            deprovision(identity)
          elsif reprovisionable?(identity) && parser.reprovision_user?
            reprovision(identity)
          elsif parsed_hash[:extern_uid]
            identity.update(parsed_hash.slice(:extern_uid))
          else
            scim_conflict!(message: 'Email has already been taken') if email_taken?(parsed_hash[:email], identity)

            result = ::Users::UpdateService.new(identity.user,
                                                parsed_hash.except(:extern_uid, :active)
                                                  .merge(user: identity.user)).execute

            result[:status] == :success
          end
        end

        def reprovisionable?(identity)
          return true if identity.respond_to?(:active) && !identity.active?

          false
        end

        def email_taken?(email, identity)
          return unless email

          User.by_any_email(email.downcase).where.not(id: identity.user.id).exists?
        end

        def find_user_identity(group, extern_uid)
          return unless group.saml_provider

          group.scim_identities.with_extern_uid(extern_uid).first
        end

        def deprovision(identity)
          ::EE::Gitlab::Scim::DeprovisionService.new(identity).execute

          true
        rescue => e
          logger.error(identity: identity, error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          false
        end

        def reprovision(identity)
          ::EE::Gitlab::Scim::ReprovisionService.new(identity).execute

          true
        rescue => e
          logger.error(identity: identity, error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          false
        end
      end

      resource :Users do
        before do
          check_group_saml_configured
        end

        desc 'Get SCIM users' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get do
          group = find_and_authenticate_group!(params[:group])

          results = ScimFinder.new(group).search(params)
          response_page = scim_paginate(results)

          status 200

          result_set = { resources: response_page, total_results: results.count, items_per_page: per_page(params[:count]), start_index: params[:startIndex] }
          present result_set, with: ::EE::API::Entities::Scim::Users
        rescue ScimFinder::UnsupportedFilter
          scim_error!(message: 'Unsupported Filter')
        end

        desc 'Get a SCIM user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get ':id', requirements: USER_ID_REQUIREMENTS do
          group = find_and_authenticate_group!(params[:group])

          identity = find_user_identity(group, params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          status 200

          present identity, with: ::EE::API::Entities::Scim::User
        end

        desc 'Create a SCIM user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        post do
          group = find_and_authenticate_group!(params[:group])
          parser = ::EE::Gitlab::Scim::ParamsParser.new(params)
          result = ::EE::Gitlab::Scim::ProvisioningService.new(group, parser.post_params).execute

          case result.status
          when :success
            status 201

            present result.identity, with: ::EE::API::Entities::Scim::User
          when :conflict
            scim_conflict!(message: "Error saving user with #{sanitize_request_parameters(params).inspect}: #{result.message}")
          when :error
            scim_error!(message: ["Error saving user with #{sanitize_request_parameters(params).inspect}", result.message].compact.join(": "))
          end
        end

        desc 'Updates a SCIM user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        patch ':id', requirements: USER_ID_REQUIREMENTS do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = find_user_identity(group, params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          updated = update_scim_user(identity)

          if updated
            no_content!
          else
            scim_error!(message: "Error updating #{identity.user.name} with #{sanitize_request_parameters(params).inspect}")
          end
        end

        desc 'Removes a SCIM user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        delete ':id', requirements: USER_ID_REQUIREMENTS do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = find_user_identity(group, params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          destroyed = deprovision(identity)

          scim_not_found!(message: "Resource #{params[:id]} not found") unless destroyed

          no_content!
        end
      end
    end
  end
end
