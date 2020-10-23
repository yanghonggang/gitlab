# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    prepend Gitlab::Graphql::Present
    prepend Gitlab::Graphql::ExposePermissions
    prepend Gitlab::Graphql::MarkdownField

    field_class Types::BaseField

    def self.accepts(*types)
      @accepts ||= []
      @accepts += types
      @accepts
    end

    # All graphql fields exposing an id, should expose a global id.
    def id
      GitlabSchema.id_from_object(object)
    end

    def self.authorized?(object, context)
      abilities = Array.wrap(authorize)
      return true if abilities.empty?

      Ability.policy_for(context[:current_user], object).allowed?(*abilities)
    end

    def self.scope_items(items, context)
      remove_unauthorized(items, context)

      items
    end

    # Mutates the input array
    def self.remove_unauthorized(array, context)
      return unless array.is_a?(Array)
      return unless authorize.present?

      array.select! do |lazy|
        forced = ::Gitlab::Graphql::Lazy.force(lazy)
        authorized?(forced, context)
      end
    end

    def current_user
      context[:current_user]
    end

    def self.assignable?(object)
      assignable = accepts

      return true if assignable.blank?

      assignable.any? { |cls| object.is_a?(cls) }
    end
  end
end
