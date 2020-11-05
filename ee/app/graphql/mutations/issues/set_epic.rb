# frozen_string_literal: true

module Mutations
  module Issues
    class SetEpic < Base
      graphql_name 'IssueSetEpic'

      argument :epic_id,
               ::Types::GlobalIDType[::Epic],
               required: false,
               loads: Types::EpicType,
               description: 'Global ID of the epic to be assigned to the issue, ' \
               'epic will be removed if absent or set to null'

      def resolve(project_path:, iid:, epic: nil)
        issue = authorized_find!(project_path: project_path, iid: iid)
        project = issue.project

        authorize_admin_rights!(epic)

        ::Issues::UpdateService.new(project, current_user, epic: epic)
          .execute(issue)

        {
          issue: issue,
          errors: issue.errors.full_messages
        }
      end

      private

      def authorize_admin_rights!(epic)
        return unless epic.present?

        raise_resource_not_available_error! unless Ability.allowed?(current_user, :admin_epic, epic.group)
      end
    end
  end
end
