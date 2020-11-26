# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PopulateRemainingMissingDismissalInformationForVulnerabilities do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:vulnerabilities) { table(:vulnerabilities) }
  let(:findings) { table(:vulnerability_occurrences) }
  let(:scanners) { table(:vulnerability_scanners) }
  let(:identifiers) { table(:vulnerability_identifiers) }
  let(:feedback) { table(:vulnerability_feedback) }

  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create!(namespace_id: namespace.id, name: 'foo') }
  let(:scanner) { scanners.create!(project_id: project.id, external_id: 'foo', name: 'bar') }
  let(:identifier) { identifiers.create!(project_id: project.id, fingerprint: 'foo', external_type: 'bar', external_id: 'zoo', name: 'identifier') }
  let!(:vulnerability_1) { vulnerabilities.create!(title: 'title', state: 0, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }
  let!(:vulnerability_2) { vulnerabilities.create!(title: 'title', state: 1, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }
  let!(:vulnerability_3) { vulnerabilities.create!(title: 'title', state: 2, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }
  let!(:vulnerability_4) { vulnerabilities.create!(title: 'title', state: 3, severity: 0, confidence: 5, report_type: 2, project_id: project.id, author_id: user.id) }

  describe '#perform' do
    it 'calls the background migration class instance with broken vulnerability IDs' do
      expect_next_instance_of(::Gitlab::BackgroundMigration::PopulateMissingVulnerabilityDismissalInformation) do |migrator|
        expect(migrator).to receive(:perform).with(vulnerability_3.id)
      end

      migrate!
    end
  end
end
