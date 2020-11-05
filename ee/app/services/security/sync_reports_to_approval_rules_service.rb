# frozen_string_literal: true

module Security
  # Service for syncing security reports results to report_approver approval rules
  #
  class SyncReportsToApprovalRulesService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      sync_license_management_rules
      sync_vulnerability_rules
      success
    rescue StandardError => error
      log_error(
        pipeline: pipeline&.to_param,
        error: error.class.name,
        message: error.message,
        source: "#{__FILE__}:#{__LINE__}",
        backtrace: error.backtrace
      )
      error("Failed to update approval rules")
    end

    private

    attr_reader :pipeline

    def sync_license_management_rules
      project = pipeline.project
      report = pipeline.license_scanning_report
      return if report.empty? && !pipeline.complete?
      return if report.violates?(project.software_license_policies)

      remove_required_approvals_for(ApprovalMergeRequestRule.report_approver.license_scanning,
                                    pipeline.merge_requests_as_head_pipeline)
    end

    def sync_vulnerability_rules
      # If we have some reports, then we want to sync them early;
      # If we don't have reports, then we should wait until pipeline stops.
      return if reports.empty? && !pipeline.complete?

      remove_required_approvals_for(ApprovalMergeRequestRule.vulnerability_report, sync_required_merge_requests)
    end

    def reports
      @reports ||= pipeline.security_reports
    end

    def sync_required_merge_requests
      pipeline.merge_requests_as_head_pipeline.reject do |merge_request|
        reports.violates_default_policy_against?(merge_request.base_pipeline&.security_reports)
      end
    end

    def remove_required_approvals_for(rules, merge_requests)
      rules
        .for_unmerged_merge_requests(merge_requests)
        .update_all(approvals_required: 0)
    end
  end
end
