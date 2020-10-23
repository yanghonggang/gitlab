# frozen_string_literal: true

module Gitlab
  module Graphql
    class ConnectionFilterExtension < GraphQL::Schema::FieldExtension
      class Redactor
        def initialize(field, context)
          @type = field.type.node_type
          @context = context
        end

        def redact(nodes)
          @type.scope_items(nodes, @context)
        end

        def active?
          @type && @type.respond_to?(:scope_items)
        end
      end

      def after_resolve(value:, context:, **rest)
        return value unless @field.connection? && value.respond_to?(:redactor)

        redactor = Redactor.new(@field, context)
        value.redactor = redactor if redactor.active?

        value
      end
    end
  end
end
