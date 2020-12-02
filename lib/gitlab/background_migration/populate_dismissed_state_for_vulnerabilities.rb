# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This class updates vulnerabilities entities with state dismissed
    class PopulateDismissedStateForVulnerabilities
      class Vulnerability < ActiveRecord::Base # rubocop:disable Style/Documentation
        self.table_name = 'vulnerabilities'
      end

      def self.vulnerability_ids_with_invalid_state
        Vulnerability.connection.exec_query <<~SQL
          SELECT "vulnerability_occurrences"."vulnerability_id"
          FROM "vulnerability_occurrences"
          JOIN "vulnerabilities"
          ON "vulnerability_occurrences"."vulnerability_id" = "vulnerabilities"."id" AND "vulnerabilities"."state" != 2
          JOIN "vulnerability_feedback"
          ON "vulnerability_occurrences"."project_id" = "vulnerability_feedback"."project_id"
            AND "vulnerability_occurrences"."report_type" = "vulnerability_feedback"."category"
            AND ENCODE("vulnerability_occurrences"."project_fingerprint", 'hex') = "vulnerability_feedback"."project_fingerprint"
            AND "vulnerability_feedback"."feedback_type" = 0
          ORDER BY "vulnerability_occurrences"."vulnerability_id" ASC;
        SQL
      end

      def perform(*vulnerability_ids)
        Vulnerability.where(id: vulnerability_ids).update_all(state: 2)
        PopulateMissingVulnerabilityDismissalInformation.new.perform(*vulnerability_ids)
      end
    end
  end
end
