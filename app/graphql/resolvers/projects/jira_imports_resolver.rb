# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      type Types::JiraImportType.connection_type, null: true

      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorize :read_project
      authorizes_object!

      alias_method :project, :object

      def resolve(**args)
        project.jira_imports
      end
    end
  end
end
