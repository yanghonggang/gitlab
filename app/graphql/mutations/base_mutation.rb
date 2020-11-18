# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    prepend Gitlab::Graphql::Authorize::AuthorizeResource
    prepend Gitlab::Graphql::CopyFieldDescription
    prepend ::Gitlab::Graphql::GlobalIDCompatibility

    ERROR_MESSAGE = 'You cannot perform write operations on a read-only instance'

    field_class ::Types::BaseField

    field :errors, [GraphQL::STRING_TYPE],
          null: false,
          description: 'Errors encountered during execution of the mutation.'

    def current_user
      context[:current_user]
    end

    def api_user?
      context[:is_sessionless_user]
    end

    # Returns Array of errors on an ActiveRecord object
    def errors_on_object(record)
      record.errors.full_messages
    end

    def ready?(**args)
      if Gitlab::Database.read_only?
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, ERROR_MESSAGE
      else
        true
      end
    end

    def self.authorized?(object, context)
      # we never provide an object to mutations, but we do need to have a user.
      context[:current_user].present? && !context[:current_user].blocked?
    end

    def authorize!(object, context = nil)
      abilities = Array.wrap(self.class.authorize)
      return if abilities.all? { |ability| Ability.allowed?(current_user, ability, object) }

      raise_resource_not_available_error!
    end
  end
end
