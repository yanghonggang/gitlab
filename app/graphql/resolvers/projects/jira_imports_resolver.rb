# frozen_string_literal: true

module Resolvers
  module Projects
    class JiraImportsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::JiraImportType.connection_type, null: true
      authorize :read_project
      authorizes_object!

      alias_method :project, :object

      def resolve(**args)
        project.jira_imports
      end
    end
  end
end
