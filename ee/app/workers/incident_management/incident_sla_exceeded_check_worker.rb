# frozen_string_literal: true

module IncidentManagement
  class IncidentSlaExceededCheckWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    feature_category :incident_management

    def perform
      IssuableSla.exceeded_for_issues.find_each do |incident_sla|
        ApplyIncidentSlaExceededLabelWorker.perform_async(incident_sla.issue_id)
      end
    end
  end
end
