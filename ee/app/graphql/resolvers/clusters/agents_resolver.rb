# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentsResolver < BaseResolver
      include LooksAhead

      type Types::Clusters::AgentType.connection_type, null: true

      extras [:lookahead]

      when_single do
        argument :name, GraphQL::STRING_TYPE,
            required: true,
            description: 'Name of the cluster agent'
      end

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        apply_lookahead(
          ::Clusters::AgentsFinder
            .new(project, current_user, params: args)
            .execute
        )
      end

      private

      def preloads
        { tokens: :agent_tokens }
      end
    end
  end
end
