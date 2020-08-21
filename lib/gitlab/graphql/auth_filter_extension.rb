# frozen_string_literal: true

module Gitlab
  module Graphql
    class AuthFilterExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:)
        # skip resolution if object is a Placeholder
        ap "FILTER resolving"
        ap object
        ap "resolve: PLACEHOLDER" if object.object == Placeholder
        return Placeholder if object.object == Placeholder

        ap "resolving as normal"
        yield(object, arguments, context)
      end

      def after_resolve(object:, arguments:, context:, value:, memo:)
        ap "Filter: after_resolve object"
        ap object
        ap "Filter: after_resolve value"
        ap value
        # if field is a connection or an array, filter out Placeholders
        ap @field
        if @field.connection?
          ap "FIELD CONNECTION"
          value.edge_nodes.to_a.keep_if { |node| !node.is_a?(Placeholder) }
        elsif @field.type.list? || value.is_a?(Array)
          ap "FIELD IS ARRAY"
          value.select { |item| !item.is_a?(Placeholder) }
        elsif value == Placeholder
          nil
        else
          value
        end
      end
    end
  end
end
