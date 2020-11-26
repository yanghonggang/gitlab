# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ExternalIssueType < BaseObject
    graphql_name 'ExternalIssue'
    description 'Represents an external issue'

    field :title, GraphQL::ID_TYPE, null: false,
          description: 'Title of the issue in external tracker'

    field :relative_reference, GraphQL::STRING_TYPE, null: false,
          description: 'Relative reference of the issue in external tracker'

    field :status, GraphQL::STRING_TYPE, null: false,
          description: 'Status of the issue in external tracker'

    field :external_tracker, GraphQL::STRING_TYPE, null: false,
          description: 'Type of external tracker'

    field :web_url, GraphQL::STRING_TYPE, null: false,
          description: 'URL to the issue in external tracker'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was created'

    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of when the issue was updated'

    def relative_reference
      object.dig(:references, :relative)
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
