# frozen_string_literal: true

module Vulnerabilities
  class Finding < ApplicationRecord
    include ShaAttribute
    include ::Gitlab::Utils::StrongMemoize
    include Presentable

    # https://gitlab.com/groups/gitlab-org/-/epics/3148
    # https://gitlab.com/gitlab-org/gitlab/-/issues/214563#note_370782508 is why the table names are not renamed
    self.table_name = "vulnerability_occurrences"

    FINDINGS_PER_PAGE = 20
    MAX_NUMBER_OF_IDENTIFIERS = 20

    paginates_per FINDINGS_PER_PAGE

    sha_attribute :project_fingerprint
    sha_attribute :location_fingerprint

    belongs_to :project, inverse_of: :vulnerability_findings
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'
    belongs_to :primary_identifier, class_name: 'Vulnerabilities::Identifier', inverse_of: :primary_findings, foreign_key: 'primary_identifier_id'
    belongs_to :vulnerability, class_name: 'Vulnerability', inverse_of: :findings, foreign_key: 'vulnerability_id'

    has_many :finding_identifiers, class_name: 'Vulnerabilities::FindingIdentifier', inverse_of: :finding, foreign_key: 'occurrence_id'
    has_many :identifiers, through: :finding_identifiers, class_name: 'Vulnerabilities::Identifier'

    has_many :finding_links, class_name: 'Vulnerabilities::FindingLink', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'

    has_many :finding_remediations, class_name: 'Vulnerabilities::FindingRemediation', inverse_of: :finding, foreign_key: 'vulnerability_occurrence_id'
    has_many :remediations, through: :finding_remediations

    has_many :finding_pipelines, class_name: 'Vulnerabilities::FindingPipeline', inverse_of: :finding, foreign_key: 'occurrence_id'
    has_many :pipelines, through: :finding_pipelines, class_name: 'Ci::Pipeline'

    attr_writer :sha
    attr_accessor :scan

    CONFIDENCE_LEVELS = {
      # undefined: 0, no longer applicable
      ignore: 1,
      unknown: 2,
      experimental: 3,
      low: 4,
      medium: 5,
      high: 6,
      confirmed: 7
    }.with_indifferent_access.freeze

    SEVERITY_LEVELS = {
      # undefined: 0, no longer applicable
      info: 1,
      unknown: 2,
      # experimental: 3, formerly used by confidence, no longer applicable
      low: 4,
      medium: 5,
      high: 6,
      critical: 7
    }.with_indifferent_access.freeze

    REPORT_TYPES = {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3,
      secret_detection: 4,
      coverage_fuzzing: 5,
      api_fuzzing: 6
    }.with_indifferent_access.freeze

    enum confidence: CONFIDENCE_LEVELS, _prefix: :confidence
    enum report_type: REPORT_TYPES
    enum severity: SEVERITY_LEVELS, _prefix: :severity

    validates :scanner, presence: true
    validates :project, presence: true
    validates :uuid, presence: true

    validates :primary_identifier, presence: true
    validates :project_fingerprint, presence: true
    validates :location_fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_id, :scanner_id, :ref, :pipeline_id, :project_id] }
    validates :name, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true
    validates :confidence, presence: true

    validates :metadata_version, presence: true
    validates :raw_metadata, presence: true

    delegate :name, :external_id, to: :scanner, prefix: true, allow_nil: true

    scope :report_type, -> (type) { where(report_type: report_types[type]) }
    scope :ordered, -> { order(severity: :desc, confidence: :desc, id: :asc) }

    scope :by_report_types, -> (values) { where(report_type: values) }
    scope :by_projects, -> (values) { where(project_id: values) }
    scope :by_severities, -> (values) { where(severity: values) }
    scope :by_confidences, -> (values) { where(confidence: values) }
    scope :by_project_fingerprints, -> (values) { where(project_fingerprint: values) }

    scope :all_preloaded, -> do
      preload(:scanner, :identifiers, project: [:namespace, :project_feature])
    end

    scope :scoped_project, -> { where('vulnerability_occurrences.project_id = projects.id') }

    def self.for_pipelines_with_sha(pipelines)
      joins(:pipelines)
        .where(ci_pipelines: { id: pipelines })
        .select("vulnerability_occurrences.*, ci_pipelines.sha")
    end

    def self.for_pipelines(pipelines)
      joins(:finding_pipelines)
        .where(vulnerability_occurrence_pipelines: { pipeline_id: pipelines })
    end

    def self.counted_by_severity
      group(:severity).count.transform_keys do |severity|
        SEVERITY_LEVELS[severity]
      end
    end

    def self.with_vulnerabilities_for_state(project:, report_type:, project_fingerprints:)
      Vulnerabilities::Finding
        .joins(:vulnerability)
        .where(
          project: project,
          report_type: report_type,
          project_fingerprint: project_fingerprints
        )
        .select('vulnerability_occurrences.report_type, vulnerability_id, project_fingerprint, raw_metadata, '\
                'vulnerabilities.id, vulnerabilities.state') # fetching only required attributes
    end

    # sha can be sourced from a joined pipeline or set from the report
    def sha
      self[:sha] || @sha
    end

    def state
      return 'dismissed' if dismissal_feedback.present?

      if vulnerability.nil?
        'detected'
      elsif vulnerability.resolved?
        'resolved'
      elsif vulnerability.dismissed? # fail-safe check for cases when dismissal feedback was lost or was not created
        'dismissed'
      else
        'confirmed'
      end
    end

    def self.related_dismissal_feedback
      Feedback
      .where(arel_table[:report_type].eq(Feedback.arel_table[:category]))
      .where(arel_table[:project_id].eq(Feedback.arel_table[:project_id]))
      .where(Arel::Nodes::NamedFunction.new('ENCODE', [arel_table[:project_fingerprint], Arel::Nodes::SqlLiteral.new("'HEX'")]).eq(Feedback.arel_table[:project_fingerprint]))
      .for_dismissal
    end
    private_class_method :related_dismissal_feedback

    def self.dismissed
      where('EXISTS (?)', related_dismissal_feedback.select(1))
    end

    def self.undismissed
      where('NOT EXISTS (?)', related_dismissal_feedback.select(1))
    end

    def self.batch_count_by_project_and_severity(project_id, severity)
      BatchLoader.for(project_id: project_id, severity: severity).batch(default_value: 0) do |items, loader|
        project_ids = items.map { |i| i[:project_id] }.uniq
        severities = items.map { |i| i[:severity] }.uniq

        latest_pipelines = Ci::Pipeline
          .where(project_id: project_ids)
          .with_vulnerabilities
          .latest_successful_ids_per_project

        counts = for_pipelines(latest_pipelines)
          .undismissed
          .by_severities(severities)
          .group(:project_id, :severity)
          .count

        counts.each do |(found_project_id, found_severity), count|
          loader_key = { project_id: found_project_id, severity: found_severity }
          loader.call(loader_key, count)
        end
      end
    end

    def feedback(feedback_type:)
      load_feedback.find { |f| f.feedback_type == feedback_type }
    end

    def load_feedback
      BatchLoader.for(finding_key).batch(replace_methods: false) do |finding_keys, loader|
        project_ids = finding_keys.map { |key| key[:project_id] }
        categories = finding_keys.map { |key| key[:category] }
        fingerprints = finding_keys.map { |key| key[:project_fingerprint] }

        feedback = Vulnerabilities::Feedback.all_preloaded.where(
          project_id: project_ids.uniq,
          category: categories.uniq,
          project_fingerprint: fingerprints.uniq
        ).to_a

        finding_keys.each do |finding_key|
          loader.call(
            finding_key,
            feedback.select { |f| finding_key == f.finding_key }
          )
        end
      end
    end

    def dismissal_feedback
      feedback(feedback_type: 'dismissal')
    end

    def issue_feedback
      Vulnerabilities::Feedback.find_by(issue: vulnerability&.related_issues) if vulnerability
    end

    def merge_request_feedback
      feedback(feedback_type: 'merge_request')
    end

    def metadata
      strong_memoize(:metadata) do
        data = Gitlab::Json.parse(raw_metadata)

        data = {} unless data.is_a?(Hash)

        data
      rescue JSON::ParserError
        {}
      end
    end

    def description
      metadata.dig('description')
    end

    def solution
      metadata.dig('solution') || remediations&.first&.dig('summary')
    end

    def location
      metadata.fetch('location', {})
    end

    def file
      location.dig('file')
    end

    def links
      return metadata.fetch('links', []) if finding_links.load.empty?

      finding_links.as_json(only: [:name, :url])
    end

    def remediations
      metadata.dig('remediations')
    end

    def build_evidence_request(data)
      return if data.nil?

      {
        headers: data.fetch('headers', []).map do |request_header|
          {
            name: request_header['name'],
            value: request_header['value']
          }
        end,
        method: data['method'],
        url: data['url'],
        body: data['body']
      }
    end

    def build_evidence_response(data)
      return if data.nil?

      {
        headers: data.fetch('headers', []).map do |header_data|
          {
            name: header_data['name'],
            value: header_data['value']
          }
        end,
        status_code: data['status_code'],
        reason_phrase: data['reason_phrase'],
        body: data['body']
      }
    end

    def build_evidence_supporting_messages(data)
      return [] if data.nil?

      data.map do |message|
        {
          name: message['name'],
          request: build_evidence_request(message['request']),
          response: build_evidence_response(message['response'])
        }
      end
    end

    def build_evidence_source(data)
      return if data.nil?

      {
        id: data['id'],
        name: data['name'],
        url: data['url']
      }
    end

    def evidence
      {
        summary: metadata.dig('evidence', 'summary'),
        request: build_evidence_request(metadata.dig('evidence', 'request')),
        response: build_evidence_response(metadata.dig('evidence', 'response')),
        source: build_evidence_source(metadata.dig('evidence', 'source')),
        supporting_messages: build_evidence_supporting_messages(metadata.dig('evidence', 'supporting_messages'))
      }
    end

    def message
      metadata.dig('message')
    end

    def cve_value
      identifiers.find(&:cve?)&.name
    end

    def cwe_value
      identifiers.find(&:cwe?)&.name
    end

    def other_identifier_values
      identifiers.select(&:other?).map(&:name)
    end

    def assets
      metadata.fetch('assets', []).map do |asset_data|
        {
          name: asset_data['name'],
          type: asset_data['type'],
          url: asset_data['url']
        }
      end
    end

    alias_method :==, :eql? # eql? is necessary in some cases like array intersection

    def eql?(other)
      other.report_type == report_type &&
        other.location_fingerprint == location_fingerprint &&
        other.first_fingerprint == first_fingerprint
    end

    # Array.difference (-) method uses hash and eql? methods to do comparison
    def hash
      # This is causing N+1 queries whenever we are calling findings, ActiveRecord uses #hash method to make sure the
      # array with findings is uniq before preloading. This method is used only in Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer
      # where we are normalizing security report findings into instances of Vulnerabilities::Finding, this is why we are using original implementation
      # when Finding is persisted and identifiers are not preloaded.
      return super if persisted? && !identifiers.loaded?

      report_type.hash ^ location_fingerprint.hash ^ first_fingerprint.hash
    end

    def severity_value
      self.class.severities[self.severity]
    end

    def confidence_value
      self.class.confidences[self.confidence]
    end

    protected

    def first_fingerprint
      identifiers.first&.fingerprint
    end

    private

    def finding_key
      {
        project_id: project_id,
        category: report_type,
        project_fingerprint: project_fingerprint
      }
    end
  end
end
