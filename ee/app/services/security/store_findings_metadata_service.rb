# frozen_string_literal: true

module Security
  # This service class stores the findings metadata for all pipelines.
  class StoreFindingsMetadataService < ::BaseService
    attr_reader :security_scan, :report

    def self.execute(security_scan, report)
      new(security_scan, report).execute
    end

    def initialize(security_scan, report)
      @security_scan = security_scan
      @report = report
    end

    def execute
      return error('Findings are already stored!') if already_stored?

      store_findings
      success
    end

    private

    delegate :findings, to: :report, prefix: true
    delegate :project, to: :security_scan

    def already_stored?
      security_scan.findings.any?
    end

    def store_findings
      report_findings.each_with_index { |report_finding, position| store_finding!(report_finding, position) }
    end

    def store_finding!(report_finding, position)
      return if report_finding.scanner.blank?

      security_scan.findings.create!(finding_data(report_finding, position))
    end

    def finding_data(report_finding, position)
      {
        severity: report_finding.severity,
        confidence: report_finding.confidence,
        project_fingerprint: report_finding.project_fingerprint,
        scanner: persisted_scanner_for(report_finding.scanner),
        position: position
      }
    end

    def persisted_scanner_for(report_scanner)
      existing_scanners[report_scanner.key] ||= create_scanner!(report_scanner)
    end

    def existing_scanners
      @existing_scanners ||= project.vulnerability_scanners
                                    .with_external_id(scanner_external_ids)
                                    .group_by(&:external_id)
                                    .transform_values(&:first)
    end

    def scanner_external_ids
      report.scanners.values.map(&:external_id)
    end

    def create_scanner!(report_scanner)
      project.vulnerability_scanners.create!(report_scanner.to_hash)
    end
  end
end
