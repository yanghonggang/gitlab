# frozen_string_literal: true

module Gitlab
  module Graphql
    class AuthFilterExtension < GraphQL::Schema::FieldExtension
      def resolve(object:, arguments:, context:)
        # skip resolution if object is a Placeholder
        yield(object, arguments)
      end

      def after_resolve(object:, arguments:, context:, value:, memo:)
        if @field.connection?
          value.edge_nodes.to_a.reject { |node| node == unauthorized }
        elsif @field.type.list? && type = unwrap(@field.type)
          value.map { |item| ::Gitlab::Graphql::Lazy.force(item) }
               .select { |item| type.authorized?(item, context) }
        else
          value
        end
      end

      # Find the first type that can do auth checks
      def unwrap(type)
        type = type.of_type while !type.respond_to?(:authorized?) && type.respond_to?(:of_type)

        type if type.respond_to?(:authorized?)
      end
    end
  end
end
