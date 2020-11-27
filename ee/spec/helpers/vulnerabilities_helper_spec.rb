# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VulnerabilitiesHelper do
  let_it_be(:user) { create(:user) }
  let(:project) { create(:project, :repository, :public) }
  let(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let(:finding) { create(:vulnerabilities_finding, pipelines: [pipeline], project: project, severity: :high) }
  let(:vulnerability) { create(:vulnerability, title: "My vulnerability", project: project, findings: [finding]) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  RSpec.shared_examples 'vulnerability properties' do
    let(:vulnerability_serializer_hash) do
      vulnerability.slice(
        :id,
        :title,
        :state,
        :severity,
        :confidence,
        :report_type,
        :resolved_on_default_branch,
        :project_default_branch,
        :resolved_by_id,
        :dismissed_by_id,
        :confirmed_by_id)
    end

    let(:finding_serializer_hash) do
      finding.slice(:description,
                    :identifiers,
                    :links,
                    :location,
                    :name,
                    :issue_feedback,
                    :project,
                    :remediations,
                    :solution)
    end

    before do
      vulnerability_serializer_stub = instance_double("VulnerabilitySerializer")
      expect(VulnerabilitySerializer).to receive(:new).and_return(vulnerability_serializer_stub)
      expect(vulnerability_serializer_stub).to receive(:represent).with(vulnerability).and_return(vulnerability_serializer_hash)

      finding_serializer_stub = instance_double("Vulnerabilities::FindingSerializer")
      expect(Vulnerabilities::FindingSerializer).to receive(:new).and_return(finding_serializer_stub)
      expect(finding_serializer_stub).to receive(:represent).with(finding).and_return(finding_serializer_hash)
    end

    around do |example|
      freeze_time { example.run }
    end

    it 'has expected vulnerability properties' do
      expect(subject).to include(
        timestamp: Time.now.to_i,
        create_issue_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/create_issue",
        create_jira_issue_url: nil,
        related_jira_issues_path: "/#{project.full_path}/-/integrations/jira/issues?vulnerability_ids%5B%5D=#{vulnerability.id}",
        has_mr: anything,
        create_mr_url: "/#{project.full_path}/-/vulnerability_feedback",
        discussions_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/discussions",
        notes_url: "/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}/notes",
        related_issues_help_path: kind_of(String),
        pipeline: anything,
        can_modify_related_issues: false
      )
    end

    context 'when the issues are disabled for the project' do
      before do
        allow(project).to receive(:issues_enabled?).and_return(false)
      end

      it 'has `create_issue_url` set as nil' do
        expect(subject).to include(create_issue_url: nil)
      end
    end
  end

  describe '#vulnerability_details' do
    before do
      allow(helper).to receive(:can?).and_return(true)
    end

    subject { helper.vulnerability_details(vulnerability, pipeline) }

    describe '[:can_modify_related_issues]' do
      context 'with security dashboard feature enabled' do
        before do
          stub_licensed_features(security_dashboard: true)
        end

        context 'when user can manage related issues' do
          before do
            project.add_developer(user)
          end

          it { is_expected.to include(can_modify_related_issues: true) }
        end

        context 'when user cannot manage related issues' do
          it { is_expected.to include(can_modify_related_issues: false) }
        end
      end

      context 'with security dashboard feature disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
          project.add_developer(user)
        end

        it { is_expected.to include(can_modify_related_issues: false) }
      end
    end

    context 'when pipeline exists' do
      subject { helper.vulnerability_details(vulnerability, pipeline) }

      include_examples 'vulnerability properties'

      it 'returns expected pipeline data' do
        expect(subject[:pipeline]).to include(
          id: pipeline.id,
          created_at: pipeline.created_at.iso8601,
          url: be_present
        )
      end
    end

    context 'when pipeline is nil' do
      subject { helper.vulnerability_details(vulnerability, nil) }

      include_examples 'vulnerability properties'

      it 'returns no pipeline data' do
        expect(subject[:pipeline]).to be_nil
      end
    end
  end

  describe '#create_jira_issue_url_for' do
    subject { helper.vulnerability_details(vulnerability, pipeline) }

    let(:jira_service) { double('JiraService', new_issue_url_with_predefined_fields: 'https://jira.example.com/new') }

    before do
      allow(helper).to receive(:can?).and_return(true)
      allow(vulnerability.project).to receive(:jira_service).and_return(jira_service)
    end

    context 'with jira vulnerabilities integration enabled' do
      before do
        allow(project).to receive(:jira_vulnerabilities_integration_enabled?).and_return(true)
      end

      let(:expected_jira_issue_description) do
        <<-JIRA.strip_heredoc
          Issue created from vulnerability [#{vulnerability.id}|http://localhost/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}]

          h3. Description:

          Description of My vulnerability

          * Severity: high
          * Confidence: medium
          * Location: [maven/src/main/java/com/gitlab/security_products/tests/App.java:29|http://localhost/#{project.full_path}/-/blob/b83d6e391c22777fca1ed3012fce84f633d7fed0/maven/src/main/java/com/gitlab/security_products/tests/App.java#L29]

          ### Solution:

          See vulnerability [#{vulnerability.id}|http://localhost/#{project.full_path}/-/security/vulnerabilities/#{vulnerability.id}] for any Solution details.


          h3. Links:

          * [Cipher does not check for integrity first?|https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first]


          h3. Scanner:

          * Name: Find Security Bugs
        JIRA
      end

      it 'renders description using dedicated template' do
        expect(ApplicationController).to receive(:render).with(template: 'vulnerabilities/jira_issue_description.md.erb', locals: { vulnerability: an_instance_of(VulnerabilityPresenter) })

        subject
      end

      it 'delegates rendering URL to JiraService' do
        expect(jira_service).to receive(:new_issue_url_with_predefined_fields).with("Investigate vulnerability: #{vulnerability.title}", expected_jira_issue_description)

        subject
      end

      it 'generates url to create issue in Jira' do
        expect(subject[:create_jira_issue_url]).to eq('https://jira.example.com/new')
      end

      context 'when scan property is empty' do
        before do
          vulnerability.finding.scan = nil
        end

        it 'renders description using dedicated template without raising error' do
          expect(ApplicationController).to receive(:render).with(template: 'vulnerabilities/jira_issue_description.md.erb', locals: { vulnerability: an_instance_of(VulnerabilityPresenter) })
          expect {subject}.not_to raise_error
        end
      end
    end

    context 'with jira vulnerabilities integration disabled' do
      before do
        allow(project).to receive(:jira_vulnerabilities_integration_enabled?).and_return(false)
      end

      it { expect(subject[:create_jira_issue_url]).to be_nil }
    end
  end

  describe '#vulnerability_finding_data' do
    subject { helper.vulnerability_finding_data(vulnerability) }

    it 'returns finding information' do
      expect(subject).to match(
        description: finding.description,
        identifiers: kind_of(Array),
        issue_feedback: anything,
        links: finding.links,
        location: finding.location,
        name: finding.name,
        merge_request_feedback: anything,
        project: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        project_fingerprint: finding.project_fingerprint,
        remediations: finding.remediations,
        solution: kind_of(String),
        evidence: kind_of(String),
        scanner: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        request: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        response: kind_of(Grape::Entity::Exposure::NestingExposure::OutputBuilder),
        evidence_source: anything,
        assets: kind_of(Array),
        supporting_messages: kind_of(Array)
      )

      expect(subject[:location]['blob_path']).to match(kind_of(String))
    end

    context 'when there is no file' do
      before do
        vulnerability.finding.location['file'] = nil
        vulnerability.finding.location.delete('blob_path')
      end

      it 'does not have a blob_path if there is no file' do
        expect(subject[:location]).not_to have_key('blob_path')
      end
    end
  end
end
