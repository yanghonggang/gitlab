# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    include Gitlab::Graphql::Authorize::AuthorizeResource
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

    def load_application_object(argument, lookup_as_type, id, context)
      ::Gitlab::Graphql::Lazy.new { super }.catch(::GraphQL::UnauthorizedError) do |e|
        Gitlab::ErrorTracking.track_exception(e, current_user: current_user&.username)
        # The default behaviour is to abort processing and return nil for the
        # entire mutation field, but not set any top-level errors. We prefer to
        # at least say that something went wrong.
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, RESOURCE_ACCESS_ERROR
      end
    end

    def self.authorized?(object, context)
      # we never provide an object to mutations, but we do need to have a user.
      context[:current_user].present? && !context[:current_user].blocked?
    end

    def authorized_resource?(object)
      abilities = Array.wrap(self.class.authorize)
      user = current_user

      abilities.all? { |ability| Ability.allowed?(user, ability, object) }
    end
  end
end
