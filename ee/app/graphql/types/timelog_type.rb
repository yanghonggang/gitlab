# frozen_string_literal: true

module Types
  class TimelogType < BaseObject
    graphql_name 'Timelog'

    authorize :read_group_timelogs

    field :spent_at,
          Types::TimeType,
          null: true,
          description: 'Timestamp of when the time tracked was spent at'

    field :time_spent,
          GraphQL::INT_TYPE,
          null: false,
          description: 'The time spent displayed in seconds'

    field :user,
          Types::UserType,
          null: false,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(User, obj.user_id).find },
          description: 'The user that logged the time'

    field :issue,
          Types::IssueType,
          null: true,
          resolve: -> (obj, _args, _ctx) { Gitlab::Graphql::Loaders::BatchModelLoader.new(Issue, obj.issue_id).find },
          description: 'The issue that logged time was added to'

    field :note,
          Types::Notes::NoteType,
          null: true,
          description: 'The note where the quick action to add the logged time was executed'
  end
end
