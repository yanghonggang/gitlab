# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::BackgroundMigration::PopulateDismissedStateForVulnerabilities, schema: 2020_11_30_103926 do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:findings) { table(:vulnerability_occurrences) }
  let(:feedback) { table(:vulnerability_feedback) }
  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:scanners) { table(:vulnerability_scanners) }

  let!(:namespace) { namespaces.create!(name: "foo", path: "bar") }
  let!(:user) { users.create!(name: 'John Doe', email: 'test@example.com', projects_limit: 5) }
  let!(:project) { projects.create!(namespace_id: namespace.id) }
  let!(:scanner) { scanners.create!(project_id: project.id, external_id: 'foo', name: 'bar') }
  let!(:identifier) { identifiers.create!(project_id: project.id, fingerprint: 'foo', external_type: 'bar', external_id: 'zoo', name: 'identifier') }
  let!(:vulnerability_params) do
    {
      project_id: project.id,
      author_id: user.id,
      title: 'Vulnerability',
      severity: 5,
      confidence: 5,
      report_type: 5
    }
  end

  let!(:identifier_1) { identifiers.create!(project_id: project.id, fingerprint: 'foo1', external_type: 'bar', external_id: 'zoo', name: 'identifier') }
  let!(:identifier_2) { identifiers.create!(project_id: project.id, fingerprint: 'foo2', external_type: 'bar', external_id: 'zoo', name: 'identifier') }

  let!(:feedback_1) { feedback.create!(feedback_type: 0, category: 'sast', project_fingerprint: '418291a26024a1445b23fe64de9380cdcdfd1fa8', project_id: project.id, author_id: user.id) }
  let!(:feedback_2) { feedback.create!(feedback_type: 0, category: 'dast', project_fingerprint: 'a98c8aed53514eddba2976b942162bf3418291a2', project_id: project.id, author_id: user.id) }

  let!(:vulnerability_1) { vulnerabilities.create!(vulnerability_params.merge(state: 1)) }
  let!(:vulnerability_2) { vulnerabilities.create!(vulnerability_params.merge(state: 3)) }
  let!(:vulnerability_3) { vulnerabilities.create!(vulnerability_params.merge(state: 2)) }

  let!(:finding_1) do
    findings.create!(name: 'Finding',
      report_type: 'sast',
      project_fingerprint: Gitlab::Database::ShaAttribute.new.serialize('418291a26024a1445b23fe64de9380cdcdfd1fa8'),
      location_fingerprint: 'bar',
      severity: 1,
      confidence: 1,
      metadata_version: 1,
      raw_metadata: '',
      uuid: SecureRandom.uuid,
      project_id: project.id,
      vulnerability_id: vulnerability_1.id,
      scanner_id: scanner.id,
      primary_identifier_id: identifier_1.id)
  end

  let!(:finding_2) do
    findings.create!(name: 'Finding',
      report_type: 'dast',
      project_fingerprint: Gitlab::Database::ShaAttribute.new.serialize('a98c8aed53514eddba2976b942162bf3418291a2'),
      location_fingerprint: 'bar',
      severity: 1,
      confidence: 1,
      metadata_version: 1,
      raw_metadata: '',
      uuid: SecureRandom.uuid,
      project_id: project.id,
      vulnerability_id: vulnerability_3.id,
      scanner_id: scanner.id,
      primary_identifier_id: identifier_2.id)
  end

  describe '.vulnerability_ids_with_invalid_state' do
    it 'returns only ids of vulnerabilities that have dismissal feedback and have state different than dismissed' do
      expect(described_class.vulnerability_ids_with_invalid_state.rows.flatten).to eq([vulnerability_1.id])
    end
  end

  describe '#perform' do
    it 'changes state of vulnerability to dismissed' do
      subject.perform(vulnerability_1.id, vulnerability_2.id)

      expect(vulnerability_1.reload.state).to eq(2)
      expect(vulnerability_2.reload.state).to eq(2)
    end

    it 'populates missing dismissal information' do
      expect_next_instance_of(::Gitlab::BackgroundMigration::PopulateMissingVulnerabilityDismissalInformation) do |migration|
        expect(migration).to receive(:perform).with(vulnerability_1.id, vulnerability_2.id)
      end

      subject.perform(vulnerability_1.id, vulnerability_2.id)
    end
  end
end
