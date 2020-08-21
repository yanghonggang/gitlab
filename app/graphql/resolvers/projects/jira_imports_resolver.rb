# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      type Types::JiraImportType.connection_type, null: true

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_project

      alias_method :project, :object

      def resolve(**args)
        raise_resource_not_available_error! unless current_user
        authorize!(project, context)

        project.jira_imports
      end
    end
  end
end
