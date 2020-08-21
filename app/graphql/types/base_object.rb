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
      # return true if object.nil? #sometimes we get nil objects??
      # return true if object.object.nil? #sometimes we get nil objects??
      return false if object == Placeholder || object.try(:object) == Placeholder

      Array.wrap(authorize).all? { |ability| Ability.allowed?(context[:current_user], ability, object) }
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
