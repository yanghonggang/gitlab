# frozen_string_literal: true

module Mutations
  module AlertManagement
    class Base < BaseMutation
      include Gitlab::Utils::UsageData

      argument :project_path, GraphQL::ID_TYPE,
               required: true,
               description: "The project the alert to mutate is in"

      argument :iid, GraphQL::STRING_TYPE,
               required: true,
               description: "The iid of the alert to mutate"

      field :alert,
            Types::AlertManagement::AlertType,
            null: true,
            description: "The alert after mutation"

      field :todo,
            Types::TodoType,
            null: true,
            description: "The todo after mutation"

      field :issue,
            Types::IssueType,
            null: true,
            description: "The issue created after mutation"

      authorize :update_alert_management_alert

      private

      def find_object(project_path:, **args)
        project = Project.find_by_full_path(project_path)

        return unless project

        ::AlertManagement::AlertsFinder.new(current_user, project, args).execute.first
      end
    end
  end
end
