# frozen_string_literal: true

module Mutations
  module Issues
    module CommonMutationArguments
      extend ActiveSupport::Concern

      included do
        argument :description, GraphQL::STRING_TYPE,
                 required: false,
                 description: copy_field_description(Types::IssueType, :description)

        argument :due_date, GraphQL::Types::ISO8601Date,
                 required: false,
                 description: copy_field_description(Types::IssueType, :due_date)

        argument :confidential, GraphQL::BOOLEAN_TYPE,
                 required: false,
                 description: copy_field_description(Types::IssueType, :confidential)

        argument :locked, GraphQL::BOOLEAN_TYPE,
                 as: :discussion_locked,
                 required: false,
                 description: copy_field_description(Types::IssueType, :discussion_locked)
      end
    end
  end
end
