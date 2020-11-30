# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class updates vulnerability feedback entities with no pipeline id assigned.
    class PopulateDismissedStateForVulnerabilities
      def perform(project_ids)
      end
    end
  end
end

Gitlab::BackgroundMigration::PopulateDismissedStateForVulnerabilities.prepend_if_ee('EE::Gitlab::BackgroundMigration::PopulateDismissedStateForVulnerabilities')
