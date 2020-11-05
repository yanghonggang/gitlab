# frozen_string_literal: true

module EE
  module Audit
    class ProjectFeatureChangesAuditor < BaseChangesAuditor
      attr_accessor :project

      COLUMNS = [:merge_requests_access_level,
                 :forking_access_level,
                 :issues_access_level,
                 :wiki_access_level,
                 :snippets_access_level,
                 :builds_access_level,
                 :repository_access_level,
                 :pages_access_level,
                 :metrics_dashboard_access_level,
                 :requirements_access_level].freeze

      def initialize(current_user, model, project)
        @project = project

        super(current_user, model)
      end

      def execute
        COLUMNS.each do |column|
          audit_changes(column, as: column.to_s, entity: @project, model: model)
        end
      end

      def attributes_from_auditable_model(column)
        base_data = { target_details: @project.full_path }

        return base_data unless COLUMNS.include?(column)

        {
          from: ::Gitlab::VisibilityLevel.level_name(model.previous_changes[column].first),
          to: ::Gitlab::VisibilityLevel.level_name(model.previous_changes[column].last)
        }.merge(base_data)
      end
    end
  end
end
