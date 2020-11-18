# frozen_string_literal: true

module Resolvers
  class MembersResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource
    include LooksAhead

    type Types::MemberInterface.connection_type, null: true

    argument :search, GraphQL::STRING_TYPE,
              required: false,
              description: 'Search query'

    def resolve_with_lookahead(**args)
      authorize!(object)

      apply_lookahead(finder_class.new(object, current_user, params: args).execute)
    end

    private

    def finder_class
      # override in subclass
    end
  end
end
