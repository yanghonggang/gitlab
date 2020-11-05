require './spec/support/sidekiq_middleware'

class Gitlab::Seeder::Vulnerabilities
  attr_reader :project

  def initialize(project)
    @project = project
    FactoryBot.definition_file_paths << Rails.root.join('ee', 'spec', 'factories')
    FactoryBot.reload # rubocop:disable Cop/ActiveRecordAssociationReload
  end

  def seed!
    return unless pipeline

    30.times do |rank|
      primary_identifier = create_identifier(rank)
      vulnerability = create_vulnerability
      occurrence = create_occurrence(vulnerability, rank, primary_identifier)
      # Create finding_pipeline join model
      occurrence.pipelines << pipeline
      # Create occurrence_identifier join models
      occurrence.identifiers << primary_identifier
      occurrence.identifiers << create_identifier(rank) if rank % 3 == 0

      if author
        case rank % 3
        when 0
          create_feedback(occurrence, 'dismissal')
        when 1
          create_feedback(occurrence, 'issue', vulnerability: vulnerability)
        else
          # no feedback
        end
      end
    end
  end

  private

  def create_vulnerability
    state_symbol = ::Vulnerability.states.keys.sample.to_sym
    vulnerability = build_vulnerability(state_symbol)

    case state_symbol
    when :resolved
      vulnerability.resolved_by = author
    when :dismissed
      vulnerability.dismissed_by = author
    end

    vulnerability.tap(&:save!)
  end

  def build_vulnerability(state_symbol)
    FactoryBot.build(
      :vulnerability,
      state_symbol,
      project: project,
      author: author,
      title: 'Cypher with no integrity',
      severity: random_severity_level,
      confidence: random_confidence_level,
      report_type: random_report_type
    )
  end

  def create_occurrence(vulnerability, rank, primary_identifier)
    scanner = FactoryBot.create(:vulnerabilities_scanner, project: vulnerability.project)
    FactoryBot.create(
      :vulnerabilities_finding,
      project: project,
      vulnerability: vulnerability,
      scanner: scanner,
      severity: random_severity_level,
      confidence: random_confidence_level,
      primary_identifier: primary_identifier,
      project_fingerprint: random_fingerprint,
      location_fingerprint: random_fingerprint,
      raw_metadata: metadata(rank).to_json
    )
  end

  def create_identifier(rank)
    FactoryBot.create(
      :vulnerabilities_identifier,
      external_type: "SECURITY_ID",
      external_id: "SECURITY_#{rank}",
      fingerprint: random_fingerprint,
      name: "SECURITY_IDENTIFIER #{rank}",
      url: "https://security.example.com/#{rank}",
      project: project
    )
  end

  def create_feedback(occurrence, type, vulnerability: nil)
    if type == 'issue'
      issue = create_issue("Dismiss #{occurrence.name}")
      create_vulnerability_issue_link(vulnerability, issue)
    end

    FactoryBot.create(
      :vulnerability_feedback,
      feedback_type: type,
      project: project,
      author: author,
      issue: issue,
      pipeline: pipeline,
      project_fingerprint: occurrence.project_fingerprint
    )
  end

  def create_issue(title)
    FactoryBot.create(
      :issue,
      project: project,
      author: author,
      title: title
    )
  end

  def create_vulnerability_issue_link(vulnerability, issue)
    FactoryBot.create(
      :vulnerabilities_issue_link,
      :created,
      vulnerability: vulnerability,
      issue: issue
    )
  end

  def random_confidence_level
    ::Vulnerabilities::Finding::CONFIDENCE_LEVELS.keys.sample
  end

  def random_severity_level
    ::Vulnerabilities::Finding::SEVERITY_LEVELS.keys.sample
  end

  def random_report_type
    ::Vulnerabilities::Finding::REPORT_TYPES.keys.sample
  end

  def metadata(line)
    {
      description: "The cipher does not provide data integrity update 1",
      solution: "GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.",
      location: {
        file: "maven/src/main/java//App.java",
        start_line: line,
        end_line: line,
        class: "com.gitlab..App",
        method: "insecureCypher"
      },
      links: [
        {
          name: "Cipher does not check for integrity first?",
          url: "https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first"
        }
      ]
    }
  end

  def random_fingerprint
    SecureRandom.hex(20)
  end

  def pipeline
    @pipeline ||= project.ci_pipelines.where(ref: project.default_branch).last
  end

  def author
    @author ||= project.users.first
  end
end

Gitlab::Seeder.quiet do
  Project.joins(:ci_pipelines).not_mass_generated.distinct.all.sample(5).each do |project|
    seeder = Gitlab::Seeder::Vulnerabilities.new(project)
    seeder.seed!
  end
end
