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
      abilities.all? { |ability| Ability.allowed?(context[:current_user], ability, object) }
    end

    def self.scope_items(items, context)
      return items unless authorize.present?

      if items.is_a?(Array)
        remove_unauthorized(items, context)
      elsif items.respond_to?(:nodes) # A connection?
        items.context ||= context
        remove_unauthorized(items.nodes, context)
      end

      items
    end

    # Mutates the input array
    def self.remove_unauthorized(array, context)
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
