# frozen_string_literal: true

module Mutations
  module Issues
    class SetIteration < Base
      graphql_name 'IssueSetIteration'

      argument :iteration_id,
               ::Types::GlobalIDType[::Iteration],
               required: false,
               loads: Types::IterationType,
               description: <<~DESC
                            The iteration to assign to the issue.
               DESC

      def resolve(project_path:, iid:, iteration: nil)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        ::Issues::UpdateService.new(project, current_user, iteration: iteration)
          .execute(issue)

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end
    end
  end
end
