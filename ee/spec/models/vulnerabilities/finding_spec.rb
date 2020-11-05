# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Finding do
  it { is_expected.to define_enum_for(:confidence) }
  it { is_expected.to define_enum_for(:report_type) }
  it { is_expected.to define_enum_for(:severity) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:primary_identifier).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to belong_to(:scanner).class_name('Vulnerabilities::Scanner') }
    it { is_expected.to belong_to(:vulnerability).inverse_of(:findings) }
    it { is_expected.to have_many(:pipelines).class_name('Ci::Pipeline') }
    it { is_expected.to have_many(:finding_pipelines).class_name('Vulnerabilities::FindingPipeline').with_foreign_key('occurrence_id') }
    it { is_expected.to have_many(:identifiers).class_name('Vulnerabilities::Identifier') }
    it { is_expected.to have_many(:finding_identifiers).class_name('Vulnerabilities::FindingIdentifier').with_foreign_key('occurrence_id') }
    it { is_expected.to have_many(:finding_links).class_name('Vulnerabilities::FindingLink').with_foreign_key('vulnerability_occurrence_id') }
  end

  describe 'validations' do
    let(:finding) { build(:vulnerabilities_finding) }

    it { is_expected.to validate_presence_of(:scanner) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }
    it { is_expected.to validate_presence_of(:primary_identifier) }
    it { is_expected.to validate_presence_of(:location_fingerprint) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:metadata_version) }
    it { is_expected.to validate_presence_of(:raw_metadata) }
    it { is_expected.to validate_presence_of(:severity) }
    it { is_expected.to validate_presence_of(:confidence) }
  end

  context 'database uniqueness' do
    let(:finding) { create(:vulnerabilities_finding) }
    let(:new_finding) { finding.dup.tap { |o| o.uuid = SecureRandom.uuid } }

    it "when all index attributes are identical" do
      expect { new_finding.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    describe 'when some parameters are changed' do
      using RSpec::Parameterized::TableSyntax

      # we use block to delay object creations
      where(:key, :factory_name) do
        :primary_identifier | :vulnerabilities_identifier
        :scanner | :vulnerabilities_scanner
        :project | :project
      end

      with_them do
        it "is valid" do
          expect { new_finding.update!({ key => create(factory_name) }) }.not_to raise_error
        end
      end
    end
  end

  context 'order' do
    let!(:finding1) { create(:vulnerabilities_finding, confidence: described_class::CONFIDENCE_LEVELS[:high], severity:   described_class::SEVERITY_LEVELS[:high]) }
    let!(:finding2) { create(:vulnerabilities_finding, confidence: described_class::CONFIDENCE_LEVELS[:medium], severity: described_class::SEVERITY_LEVELS[:critical]) }
    let!(:finding3) { create(:vulnerabilities_finding, confidence: described_class::CONFIDENCE_LEVELS[:high], severity:   described_class::SEVERITY_LEVELS[:critical]) }

    it 'orders by severity and confidence' do
      expect(described_class.all.ordered).to eq([finding3, finding2, finding1])
    end
  end

  describe '.report_type' do
    let(:report_type) { :sast }

    subject { described_class.report_type(report_type) }

    context 'when finding has the corresponding report type' do
      let!(:finding) { create(:vulnerabilities_finding, report_type: report_type) }

      it 'selects the finding' do
        is_expected.to eq([finding])
      end
    end

    context 'when finding does not have security reports' do
      let!(:finding) { create(:vulnerabilities_finding, report_type: :dependency_scanning) }

      it 'does not select the finding' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_pipelines_with_sha' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }

    before do
      create(:vulnerabilities_finding, pipelines: [pipeline], project: project)
    end

    subject(:findings) { described_class.for_pipelines_with_sha([pipeline]) }

    it 'sets the sha' do
      expect(findings.first.sha).to eq(pipeline.sha)
    end
  end

  describe '.by_report_types' do
    let!(:vulnerability_sast) { create(:vulnerabilities_finding, report_type: :sast) }
    let!(:vulnerability_secret_detection) { create(:vulnerabilities_finding, report_type: :secret_detection) }
    let!(:vulnerability_dast) { create(:vulnerabilities_finding, report_type: :dast) }
    let!(:vulnerability_depscan) { create(:vulnerabilities_finding, report_type: :dependency_scanning) }
    let!(:vulnerability_covfuzz) { create(:vulnerabilities_finding, report_type: :coverage_fuzzing) }
    let!(:vulnerability_apifuzz) { create(:vulnerabilities_finding, report_type: :api_fuzzing) }

    subject { described_class.by_report_types(param) }

    context 'with one param' do
      let(:param) { Vulnerabilities::Finding::REPORT_TYPES['sast'] }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_sast)
      end
    end

    context 'with array of params' do
      let(:param) do
        [
          Vulnerabilities::Finding::REPORT_TYPES['dependency_scanning'],
          Vulnerabilities::Finding::REPORT_TYPES['dast'],
          Vulnerabilities::Finding::REPORT_TYPES['secret_detection'],
          Vulnerabilities::Finding::REPORT_TYPES['coverage_fuzzing'],
          Vulnerabilities::Finding::REPORT_TYPES['api_fuzzing']
        ]
      end

      it 'returns found records' do
        is_expected.to contain_exactly(
          vulnerability_dast,
          vulnerability_depscan,
          vulnerability_secret_detection,
          vulnerability_covfuzz,
          vulnerability_apifuzz)
      end
    end

    context 'without found record' do
      let(:param) { Vulnerabilities::Finding::REPORT_TYPES['container_scanning']}

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.by_projects' do
    let!(:vulnerability1) { create(:vulnerabilities_finding) }
    let!(:vulnerability2) { create(:vulnerabilities_finding) }

    subject { described_class.by_projects(param) }

    context 'with found record' do
      let(:param) { vulnerability1.project_id }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability1)
      end
    end
  end

  describe '.by_severities' do
    let!(:vulnerability_high) { create(:vulnerabilities_finding, severity: :high) }
    let!(:vulnerability_low) { create(:vulnerabilities_finding, severity: :low) }

    subject { described_class.by_severities(param) }

    context 'with one param' do
      let(:param) { described_class.severities[:low] }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_low)
      end
    end

    context 'without found record' do
      let(:param) { described_class.severities[:unknown] }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.by_confidences' do
    let!(:vulnerability_high) { create(:vulnerabilities_finding, confidence: :high) }
    let!(:vulnerability_low) { create(:vulnerabilities_finding, confidence: :low) }

    subject { described_class.by_confidences(param) }

    context 'with matching param' do
      let(:param) { described_class.confidences[:low] }

      it 'returns found record' do
        is_expected.to contain_exactly(vulnerability_low)
      end
    end

    context 'with non-matching param' do
      let(:param) { described_class.confidences[:unknown] }

      it 'returns empty collection' do
        is_expected.to be_empty
      end
    end
  end

  describe '.counted_by_severity' do
    let!(:high_vulnerabilities) { create_list(:vulnerabilities_finding, 3, severity: :high) }
    let!(:medium_vulnerabilities) { create_list(:vulnerabilities_finding, 2, severity: :medium) }
    let!(:low_vulnerabilities) { create_list(:vulnerabilities_finding, 1, severity: :low) }

    subject { described_class.counted_by_severity }

    it 'returns counts' do
      is_expected.to eq({ 4 => 1, 5 => 2, 6 => 3 })
    end
  end

  describe '.undismissed' do
    let_it_be(:project) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let!(:finding1) { create(:vulnerabilities_finding, project: project) }
    let!(:finding2) { create(:vulnerabilities_finding, project: project, report_type: :dast) }
    let!(:finding3) { create(:vulnerabilities_finding, project: project2) }

    before do
      create(
        :vulnerability_feedback,
        :dismissal,
        project: finding1.project,
        project_fingerprint: finding1.project_fingerprint
      )
      create(
        :vulnerability_feedback,
        :dismissal,
        project_fingerprint: finding2.project_fingerprint,
        project: project2
      )
      create(
        :vulnerability_feedback,
        :dismissal,
        category: :sast,
        project_fingerprint: finding2.project_fingerprint,
        project: finding2.project
      )
    end

    it 'returns all non-dismissed findings' do
      expect(described_class.undismissed).to contain_exactly(finding2, finding3)
    end

    it 'returns non-dismissed findings for project' do
      expect(project2.vulnerability_findings.undismissed).to contain_exactly(finding3)
    end
  end

  describe '.dismissed' do
    let_it_be(:project) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let!(:finding1) { create(:vulnerabilities_finding, project: project) }
    let!(:finding2) { create(:vulnerabilities_finding, project: project, report_type: :dast) }
    let!(:finding3) { create(:vulnerabilities_finding, project: project2) }

    before do
      create(
        :vulnerability_feedback,
        :dismissal,
        project: finding1.project,
        project_fingerprint: finding1.project_fingerprint
      )
      create(
        :vulnerability_feedback,
        :dismissal,
        project_fingerprint: finding2.project_fingerprint,
        project: project2
      )
      create(
        :vulnerability_feedback,
        :dismissal,
        category: :sast,
        project_fingerprint: finding2.project_fingerprint,
        project: finding2.project
      )
    end

    it 'returns all dismissed findings' do
      expect(described_class.dismissed).to contain_exactly(finding1)
    end

    it 'returns dismissed findings for project' do
      expect(project.vulnerability_findings.dismissed).to contain_exactly(finding1)
    end
  end

  describe '.batch_count_by_project_and_severity' do
    let(:pipeline) { create(:ci_pipeline, :success, project: project) }
    let(:project) { create(:project) }

    it 'fetches a vulnerability count for the given project and severity' do
      create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)

      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(1)
    end

    it 'only returns vulnerabilities from the latest successful pipeline' do
      old_pipeline = create(:ci_pipeline, :success, project: project)
      latest_pipeline = create(:ci_pipeline, :success, project: project)
      latest_failed_pipeline = create(:ci_pipeline, :failed, project: project)
      create(:vulnerabilities_finding, pipelines: [old_pipeline], project: project, severity: :critical)
      create(
        :vulnerabilities_finding,
        pipelines: [latest_failed_pipeline],
        project: project,
        severity: :critical
      )
      create_list(
        :vulnerabilities_finding, 2,
        pipelines: [latest_pipeline],
        project: project,
        severity: :critical
      )

      count = described_class.batch_count_by_project_and_severity(project.id, 'critical')

      expect(count).to be(2)
    end

    it 'returns 0 when there are no vulnerabilities for that severity level' do
      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(0)
    end

    it 'batch loads the counts' do
      projects = create_list(:project, 2)

      projects.each do |project|
        pipeline = create(:ci_pipeline, :success, project: project)

        create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
        create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :low)
      end

      projects_and_severities = [
        [projects.first, 'high'],
        [projects.first, 'low'],
        [projects.second, 'high'],
        [projects.second, 'low']
      ]

      counts = projects_and_severities.map do |(project, severity)|
        described_class.batch_count_by_project_and_severity(project.id, severity)
      end

      expect { expect(counts).to all(be 1) }.not_to exceed_query_limit(1)
    end

    it 'does not include dismissed vulnerabilities in the counts' do
      create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
      dismissed_vulnerability = create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high)
      create(
        :vulnerability_feedback,
        project: project,
        project_fingerprint: dismissed_vulnerability.project_fingerprint,
        feedback_type: :dismissal
      )

      count = described_class.batch_count_by_project_and_severity(project.id, 'high')

      expect(count).to be(1)
    end

    it "does not overwrite one project's counts with another's" do
      project1 = create(:project)
      project2 = create(:project)
      pipeline1 = create(:ci_pipeline, :success, project: project1)
      pipeline2 = create(:ci_pipeline, :success, project: project2)
      create(:vulnerabilities_finding, pipelines: [pipeline1], project: project1, severity: :critical)
      create(:vulnerabilities_finding, pipelines: [pipeline2], project: project2, severity: :high)

      project1_critical_count = described_class.batch_count_by_project_and_severity(project1.id, 'critical')
      project1_high_count = described_class.batch_count_by_project_and_severity(project1.id, 'high')
      project2_critical_count = described_class.batch_count_by_project_and_severity(project2.id, 'critical')
      project2_high_count = described_class.batch_count_by_project_and_severity(project2.id, 'high')

      expect(project1_critical_count).to be(1)
      expect(project1_high_count).to be(0)
      expect(project2_critical_count).to be(0)
      expect(project2_high_count).to be(1)
    end
  end

  describe '#links' do
    let_it_be(:finding, reload: true) do
      create(
        :vulnerabilities_finding,
        raw_metadata: {
          links: [{ url: 'https://raw.gitlab.com', name: 'raw_metadata_link' }]
        }.to_json
      )
    end

    subject(:links) { finding.links }

    context 'when there are no finding links' do
      it 'returns links from raw_metadata' do
        expect(links).to eq([{ 'url' => 'https://raw.gitlab.com', 'name' => 'raw_metadata_link' }])
      end
    end

    context 'when there are finding links assigned to given finding' do
      let_it_be(:finding_link) { create(:finding_link, name: 'finding_link', url: 'https://link.gitlab.com', finding: finding) }

      it 'returns links from finding link' do
        expect(links).to eq([{ 'url' => 'https://link.gitlab.com', 'name' => 'finding_link' }])
      end
    end
  end

  describe 'feedback' do
    let_it_be(:project) { create(:project) }
    let(:finding) do
      create(
        :vulnerabilities_finding,
        report_type: :dependency_scanning,
        project: project
      )
    end

    describe '#issue_feedback' do
      let(:issue) { create(:issue, project: project) }
      let!(:issue_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :issue,
          issue: issue,
          project: project,
          project_fingerprint: finding.project_fingerprint
        )
      end

      let(:vulnerability) { create(:vulnerability, findings: [finding]) }
      let!(:issue_link) { create(:vulnerabilities_issue_link, vulnerability: vulnerability, issue: issue)}

      it 'returns associated feedback' do
        feedback = finding.issue_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'issue'
        expect(feedback[:issue_id]).to eq issue.id
      end

      context 'when there is no feedback for the vulnerability' do
        let(:vulnerability_no_feedback) { create(:vulnerability, findings: [finding_no_feedback]) }
        let!(:finding_no_feedback) { create(:vulnerabilities_finding, :dependency_scanning, project: project) }

        it 'does not return unassociated feedback' do
          feedback = finding_no_feedback.issue_feedback

          expect(feedback).not_to be_present
        end
      end

      context 'when there is no vulnerability associated with the finding' do
        let!(:finding_no_vulnerability) { create(:vulnerabilities_finding, :dependency_scanning, project: project) }

        it 'does not return feedback' do
          feedback = finding_no_vulnerability.issue_feedback

          expect(feedback).not_to be_present
        end
      end
    end

    describe '#dismissal_feedback' do
      let!(:dismissal_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :dismissal,
          project: project,
          project_fingerprint: finding.project_fingerprint
        )
      end

      it 'returns associated feedback' do
        feedback = finding.dismissal_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'dismissal'
      end
    end

    describe '#merge_request_feedback' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let!(:merge_request_feedback) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :merge_request,
          merge_request: merge_request,
          project: project,
          project_fingerprint: finding.project_fingerprint
        )
      end

      it 'returns associated feedback' do
        feedback = finding.merge_request_feedback

        expect(feedback).to be_present
        expect(feedback[:project_id]).to eq project.id
        expect(feedback[:feedback_type]).to eq 'merge_request'
        expect(feedback[:merge_request_id]).to eq merge_request.id
      end
    end
  end

  describe '#load_feedback' do
    let_it_be(:project) { create(:project) }
    let_it_be(:finding) do
      create(
        :vulnerabilities_finding,
        report_type: :dependency_scanning,
        project: project
      )
    end
    let_it_be(:feedback) do
      create(
        :vulnerability_feedback,
        :dependency_scanning,
        :dismissal,
        project: project,
        project_fingerprint: finding.project_fingerprint
      )
    end

    let(:expected_feedback) { [feedback] }

    subject(:load_feedback) { finding.load_feedback.to_a }

    it { is_expected.to eq(expected_feedback) }

    context 'when you have multiple findings' do
      let_it_be(:finding_2) do
        create(
          :vulnerabilities_finding,
          report_type: :dependency_scanning,
          project: project
        )
      end

      let_it_be(:feedback_2) do
        create(
          :vulnerability_feedback,
          :dependency_scanning,
          :dismissal,
          project: project,
          project_fingerprint: finding_2.project_fingerprint
        )
      end

      let(:expected_feedback) { [[feedback], [feedback_2]] }

      subject(:load_feedback) { [finding, finding_2].map(&:load_feedback) }

      it { is_expected.to eq(expected_feedback) }
    end
  end

  describe '#state' do
    before do
      create(:vulnerability, :dismissed, project: finding_with_issue.project, findings: [finding_with_issue])
    end

    let(:unresolved_finding) { create(:vulnerabilities_finding) }
    let(:confirmed_finding) { create(:vulnerabilities_finding, :confirmed) }
    let(:resolved_finding) { create(:vulnerabilities_finding, :resolved) }
    let(:dismissed_finding) { create(:vulnerabilities_finding, :dismissed) }
    let(:finding_with_issue) { create(:vulnerabilities_finding, :with_issue_feedback) }

    it 'returns the expected state for a unresolved finding' do
      expect(unresolved_finding.state).to eq 'detected'
    end

    it 'returns the expected state for a confirmed finding' do
      expect(confirmed_finding.state).to eq 'confirmed'
    end

    it 'returns the expected state for a resolved finding' do
      expect(resolved_finding.state).to eq 'resolved'
    end

    it 'returns the expected state for a dismissed finding' do
      expect(dismissed_finding.state).to eq 'dismissed'
    end

    context 'when a vulnerability present for a dismissed finding' do
      before do
        create(:vulnerability, project: dismissed_finding.project, findings: [dismissed_finding])
      end

      it 'still reports a dismissed state' do
        expect(dismissed_finding.state).to eq 'dismissed'
      end
    end

    context 'when a non-dismissal feedback present for a finding belonging to a closed vulnerability' do
      before do
        create(:vulnerability_feedback, :issue, project: resolved_finding.project)
      end

      it 'reports as resolved' do
        expect(resolved_finding.state).to eq 'resolved'
      end
    end
  end

  describe '#scanner_name' do
    let(:vulnerabilities_finding) { create(:vulnerabilities_finding) }

    subject(:scanner_name) { vulnerabilities_finding.scanner_name }

    it { is_expected.to eq(vulnerabilities_finding.scanner.name) }
  end

  describe '#solution' do
    subject { vulnerabilities_finding.solution }

    context 'when solution metadata key is present' do
      let(:vulnerabilities_finding) { build(:vulnerabilities_finding) }

      it { is_expected.to eq(vulnerabilities_finding.metadata['solution']) }
    end

    context 'when remediations key is present' do
      let(:vulnerabilities_finding) do
        build(:vulnerabilities_finding_with_remediation, summary: "Test remediation")
      end

      it { is_expected.to eq(vulnerabilities_finding.remediations.dig(0, 'summary')) }
    end
  end

  describe '#evidence' do
    subject { finding.evidence }

    context 'has an evidence fields' do
      let(:finding) { create(:vulnerabilities_finding) }
      let(:evidence) { finding.metadata['evidence'] }

      it do
        is_expected.to match a_hash_including(
          summary: evidence['summary'],
          request: {
            headers: [
              {
                name: evidence['request']['headers'][0]['name'],
                value: evidence['request']['headers'][0]['value']
              }
            ],
            url: evidence['request']['url'],
            method: evidence['request']['method'],
            body: evidence['request']['body']
          },
          response: {
            headers: [
              {
                name: evidence['response']['headers'][0]['name'],
                value: evidence['response']['headers'][0]['value']
              }
            ],
            reason_phrase: evidence['response']['reason_phrase'],
            status_code: evidence['response']['status_code'],
            body: evidence['request']['body']
          },
          source: {
            id: evidence.dig('source', 'id'),
            name: evidence.dig('source', 'name'),
            url: evidence.dig('source', 'url')
          },
          supporting_messages: [
            {
              name: evidence.dig('supporting_messages')[0].dig('name'),
              request: {
                headers: [
                  {
                    name: evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('name'),
                    value: evidence.dig('supporting_messages')[0].dig('request', 'headers')[0].dig('value')
                  }
                ],
                url: evidence.dig('supporting_messages')[0].dig('request', 'url'),
                method: evidence.dig('supporting_messages')[0].dig('request', 'method'),
                body: evidence.dig('supporting_messages')[0].dig('request', 'body')
              },
              response: evidence.dig('supporting_messages')[0].dig('response')
            },
            {
              name: evidence.dig('supporting_messages')[1].dig('name'),
              request: {
                headers: [
                  {
                    name: evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('name'),
                    value: evidence.dig('supporting_messages')[1].dig('request', 'headers')[0].dig('value')
                  }
                ],
                url: evidence.dig('supporting_messages')[1].dig('request', 'url'),
                method: evidence.dig('supporting_messages')[1].dig('request', 'method'),
                body: evidence.dig('supporting_messages')[1].dig('request', 'body')
              },
              response: {
                headers: [
                  {
                    name: evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('name'),
                    value: evidence.dig('supporting_messages')[1].dig('response', 'headers')[0].dig('value')
                  }
                ],
                reason_phrase: evidence.dig('supporting_messages')[1].dig('response', 'reason_phrase'),
                status_code: evidence.dig('supporting_messages')[1].dig('response', 'status_code'),
                body: evidence.dig('supporting_messages')[1].dig('response', 'body')
              }
            }
          ]
        )
      end
    end

    context 'has no evidence summary when evidence is present, summary is not' do
      let(:finding) { create(:vulnerabilities_finding, raw_metadata: { evidence: {} }) }

      it do
        is_expected.to match a_hash_including(
          summary: nil,
          source: nil,
          supporting_messages: [],
          request: nil,
          response: nil)
      end
    end
  end

  describe '#message' do
    let(:finding) { build(:vulnerabilities_finding) }
    let(:expected_message) { finding.metadata['message'] }

    subject { finding.message }

    it { is_expected.to eql(expected_message) }
  end

  describe '#cve_value' do
    let(:finding) { build(:vulnerabilities_finding) }
    let(:expected_cve) { 'CVE-2020-0000' }

    subject { finding.cve_value }

    before do
      finding.identifiers << build(:vulnerabilities_identifier, external_type: 'cve', name: expected_cve)
    end

    it { is_expected.to eql(expected_cve) }
  end

  describe '#cwe_value' do
    let(:finding) { build(:vulnerabilities_finding) }
    let(:expected_cwe) { 'CWE-0000' }

    subject { finding.cwe_value }

    before do
      finding.identifiers << build(:vulnerabilities_identifier, external_type: 'cwe', name: expected_cwe)
    end

    it { is_expected.to eql(expected_cwe) }
  end

  describe '#other_identifier_values' do
    let(:finding) { build(:vulnerabilities_finding) }
    let(:expected_values) { ['ID 1', 'ID 2'] }

    subject { finding.other_identifier_values }

    before do
      finding.identifiers << build(:vulnerabilities_identifier, external_type: 'foo', name: expected_values.first)
      finding.identifiers << build(:vulnerabilities_identifier, external_type: 'bar', name: expected_values.second)
    end

    it { is_expected.to match_array(expected_values) }
  end

  describe "#metadata" do
    let(:finding) { build(:vulnerabilities_finding) }

    subject { finding.metadata }

    it "handles bool JSON data" do
      allow(finding).to receive(:raw_metadata) { "true" }

      expect(subject).to eq({})
    end

    it "handles string JSON data" do
      allow(finding).to receive(:raw_metadata) { '"test"' }

      expect(subject).to eq({})
    end

    it "parses JSON data" do
      allow(finding).to receive(:raw_metadata) { '{ "test": true }' }

      expect(subject).to eq({ "test" => true })
    end
  end
end
