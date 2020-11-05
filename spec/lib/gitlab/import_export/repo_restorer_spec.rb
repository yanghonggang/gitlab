# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RepoRestorer do
  include GitHelpers

  describe 'bundle a project Git repo' do
    let(:user) { create(:user) }
    let!(:project_with_repo) { create(:project, :repository, name: 'test-repo-restorer', path: 'test-repo-restorer') }
    let!(:project) { create(:project) }
    let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
    let(:shared) { project.import_export_shared }
    let(:bundler) { Gitlab::ImportExport::RepoSaver.new(project: project_with_repo, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }

    subject { described_class.new(path_to_bundle: bundle_path, shared: shared, project: project) }

    before do
      allow_next_instance_of(Gitlab::ImportExport) do |instance|
        allow(instance).to receive(:storage_path).and_return(export_path)
      end

      bundler.save
    end

    after do
      FileUtils.rm_rf(export_path)
      Gitlab::GitalyClient::StorageSettings.allow_disk_access do
        FileUtils.rm_rf(project_with_repo.repository.path_to_repo)
        FileUtils.rm_rf(project.repository.path_to_repo)
      end
    end

    it 'restores the repo successfully' do
      expect(subject.restore).to be_truthy
    end

    context 'when the repository already exists' do
      it 'deletes the existing repository before importing' do
        allow(project.repository).to receive(:exists?).and_return(true)
        allow(project.repository).to receive(:path).and_return('repository_path')

        expect_next_instance_of(Repositories::DestroyService) do |instance|
          expect(instance).to receive(:execute).and_call_original
        end

        expect(shared.logger).to receive(:info).with(
          message: 'Deleting existing "repository_path" to re-import it.'
        )

        expect(subject.restore).to be_truthy
      end
    end
  end
end
