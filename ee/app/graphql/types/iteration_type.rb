# frozen_string_literal: true

module Types
  class IterationType < BaseObject
    graphql_name 'Iteration'
    description 'Represents an iteration object'

    present_using IterationPresenter

    authorize :read_iteration

    implements ::Types::TimeboxReportInterface

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the iteration'

    field :iid, GraphQL::ID_TYPE, null: false,
          description: 'Internal ID of the iteration'

    field :title, GraphQL::STRING_TYPE, null: false,
          description: 'Title of the iteration'

    field :description, GraphQL::STRING_TYPE, null: true,
          description: 'Description of the iteration'
    markdown_field :description_html, null: true

    field :state, Types::IterationStateEnum, null: false,
          description: 'State of the iteration'

    field :web_path, GraphQL::STRING_TYPE, null: false, method: :iteration_path,
          description: 'Web path of the iteration'

    field :web_url, GraphQL::STRING_TYPE, null: false, method: :iteration_url,
          description: 'Web URL of the iteration'

    field :scoped_path, GraphQL::STRING_TYPE, null: true, method: :scoped_iteration_path, extras: [:parent],
          description: 'Web path of the iteration, scoped to the query parent. Only valid for Project parents. Returns null in other contexts'

    field :scoped_url, GraphQL::STRING_TYPE, null: true, method: :scoped_iteration_url, extras: [:parent],
          description: 'Web URL of the iteration, scoped to the query parent. Only valid for Project parents. Returns null in other contexts'

    field :due_date, Types::TimeType, null: true,
          description: 'Timestamp of the iteration due date'

    field :start_date, Types::TimeType, null: true,
          description: 'Timestamp of the iteration start date'

    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of iteration creation'

    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of last iteration update'
  end
end
