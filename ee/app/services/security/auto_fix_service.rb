# frozen_string_literal: true

module Security
  class AutoFixService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute(vulnerability_ids)
      return if Feature.disabled?(:security_auto_fix)
      return if auto_fix_enabled_types.empty?

      vulnerabilities = Vulnerabilities::Finding.where(id: vulnerability_ids, report_type: auto_fix_enabled_types)

      vulnerabilities.each do |vulnerability|
        next if !!vulnerability.merge_request_feedback.try(:merge_request_iid)

        remediation = vulnerability.remediations.last

        next unless remediation

        VulnerabilityFeedback::CreateService.new(project, User.security_bot, service_params(vulnerability)).execute
      end
    end

    private

    def auto_fix_enabled_types
      return @auto_fix_enabled_types if @auto_fix_enabled_types

      setting ||= ProjectSecuritySetting.safe_find_or_create_for(project)

      # this is a temp solution and it shouldn't go to master
      @auto_fix_enabled_types = []
      @auto_fix_enabled_types.push(:dependency_scanning) if setting.auto_fix_dependency_scanning
      @auto_fix_enabled_types.push(:container_scanning) if setting.auto_fix_container_scanning
      @auto_fix_enabled_types
    end

    def service_params(vulnerability)
      {
        feedback_type: :merge_request,
        category: vulnerability.report_type,
        project_fingerprint: vulnerability.project_fingerprint,
        vulnerability_data: {
          severity: vulnerability.severity,
          confidence: vulnerability.confidence,
          description: vulnerability.description,
          solution: vulnerability.solution,
          remediations: vulnerability.remediations,
          category: vulnerability.report_type,
          title: vulnerability.name,
          name: vulnerability.name,
          location: vulnerability.location,
          links: vulnerability.links,
          identifiers: vulnerability.identifiers.map { |i| i.attributes }
        }
      }
    end
  end
end
