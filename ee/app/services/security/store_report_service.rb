# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline, :report, :project

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project
    end

    def execute
      # Ensure we're not trying to insert data twice for this report
      return error("#{@report.type} report already stored for this pipeline, skipping...") if executed?

      vulnerability_ids = create_all_vulnerabilities!
      mark_as_resolved_except(vulnerability_ids)

      success
    end

    private

    def executed?
      pipeline.vulnerability_findings.report_type(@report.type).any?
    end

    def create_all_vulnerabilities!
      @report.findings.map { |finding| create_vulnerability_finding(finding)&.id }.compact.uniq
    end

    def mark_as_resolved_except(vulnerability_ids)
      project.vulnerabilities
             .with_report_types(report.type)
             .id_not_in(vulnerability_ids)
             .update_all(resolved_on_default_branch: true)
    end

    def create_vulnerability_finding(finding)
      unless finding.valid?
        put_warning_for(finding)
        return
      end

      vulnerability_params = finding.to_hash.except(:compare_key, :identifiers, :location, :scanner, :scan, :links)
      vulnerability_params[:uuid] = calculate_uuid_v5(finding)
      vulnerability_finding = create_or_find_vulnerability_finding(finding, vulnerability_params)

      update_vulnerability_scanner(finding)

      update_vulnerability_finding(vulnerability_finding, vulnerability_params)

      # The maximum number of identifiers is not used in validation
      # we just want to ignore the rest if a finding has more than that.
      finding.identifiers.take(Vulnerabilities::Finding::MAX_NUMBER_OF_IDENTIFIERS).map do |identifier| # rubocop: disable CodeReuse/ActiveRecord
        create_or_update_vulnerability_identifier_object(vulnerability_finding, identifier)
      end

      create_or_update_vulnerability_links(finding, vulnerability_finding)

      create_vulnerability_pipeline_object(vulnerability_finding, pipeline)

      create_vulnerability(vulnerability_finding, pipeline)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def create_or_find_vulnerability_finding(finding, create_params)
      find_params = {
        scanner: scanners_objects[finding.scanner.key],
        primary_identifier: identifiers_objects[finding.primary_identifier.key],
        location_fingerprint: finding.location.fingerprint
      }

      begin
        vulnerability_finding = project
          .vulnerability_findings
          .create_with(create_params)
          .find_or_initialize_by(find_params)

        vulnerability_finding.save!
        vulnerability_finding
      rescue ActiveRecord::RecordNotUnique
        project.vulnerability_findings.find_by!(find_params)
      rescue ActiveRecord::RecordInvalid => e
        Gitlab::ErrorTracking.track_and_raise_exception(e, create_params: create_params&.dig(:raw_metadata))
      end
    end

    def calculate_uuid_v5(vulnerability_finding)
      uuid_v5_name_components = {
        report_type: vulnerability_finding.report_type,
        primary_identifier_fingerprint: vulnerability_finding.primary_fingerprint,
        location_fingerprint: vulnerability_finding.location.fingerprint,
        project_id: project.id
      }

      if uuid_v5_name_components.values.any?(&:nil?)
        Gitlab::AppLogger.warn(message: "One or more UUID name components are nil", components: uuid_v5_name_components)
      end

      name = uuid_v5_name_components.values.join('-')

      Gitlab::Vulnerabilities::CalculateFindingUUID.call(name)
    end

    def update_vulnerability_scanner(finding)
      scanner = scanners_objects[finding.scanner.key]
      scanner.update!(finding.scanner.to_hash)
    end

    def update_vulnerability_finding(vulnerability_finding, update_params)
      vulnerability_finding.update!(update_params)
    end

    def create_or_update_vulnerability_identifier_object(vulnerability_finding, identifier)
      identifier_object = identifiers_objects[identifier.key]
      vulnerability_finding.finding_identifiers.find_or_create_by!(identifier: identifier_object)
      identifier_object.update!(identifier.to_hash)
    rescue ActiveRecord::RecordNotUnique
    end

    def create_or_update_vulnerability_links(finding, vulnerability_finding)
      return if finding.links.blank?

      finding.links.each do |link|
        vulnerability_finding.finding_links.safe_find_or_create_by!(link.to_hash)
      end
    rescue ActiveRecord::RecordNotUnique
    end

    def create_vulnerability_pipeline_object(vulnerability_finding, pipeline)
      vulnerability_finding.finding_pipelines.find_or_create_by!(pipeline: pipeline)
    rescue ActiveRecord::RecordNotUnique
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_vulnerability(vulnerability_finding, pipeline)
      if vulnerability_finding.vulnerability_id
        Vulnerabilities::UpdateService.new(vulnerability_finding.project, pipeline.user, finding: vulnerability_finding, resolved_on_default_branch: false).execute
      else
        Vulnerabilities::CreateService.new(vulnerability_finding.project, pipeline.user, finding_id: vulnerability_finding.id).execute
      end
    end

    def scanners_objects
      strong_memoize(:scanners_objects) do
        @report.scanners.map do |key, scanner|
          [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner&.to_hash)]
        end.to_h
      end
    end

    def all_scanners_external_ids
      @report.scanners.values.map(&:external_id)
    end

    def existing_scanner_objects
      strong_memoize(:existing_scanner_objects) do
        project.vulnerability_scanners.with_external_id(all_scanners_external_ids).map do |scanner|
          [scanner.external_id, scanner]
        end.to_h
      end
    end

    def identifiers_objects
      strong_memoize(:identifiers_objects) do
        @report.identifiers.map do |key, identifier|
          [key, existing_identifiers_objects[key] || project.vulnerability_identifiers.build(identifier.to_hash)]
        end.to_h
      end
    end

    def all_identifiers_fingerprints
      @report.identifiers.values.map(&:fingerprint)
    end

    def existing_identifiers_objects
      strong_memoize(:existing_identifiers_objects) do
        project.vulnerability_identifiers.with_fingerprint(all_identifiers_fingerprints).map do |identifier|
          [identifier.fingerprint, identifier]
        end.to_h
      end
    end

    def put_warning_for(finding)
      Gitlab::AppLogger.warn(message: "Invalid vulnerability finding record found", finding: finding.to_hash)
    end
  end
end
