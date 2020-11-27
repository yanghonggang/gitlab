# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '[EE] Private Project Access' do
  include AccessMatchers

  let_it_be(:project) { create(:project, :private, :repository) }

  describe 'GET/:project_path/insights' do
    before do
      stub_licensed_features(insights: true)
    end

    subject { project_insights_path(project) }

    it('is allowed for admin when admin mode is enabled', :enable_admin_mode) { is_expected.to be_allowed_for(:admin) }
    it('is denied for admin when admin mode is disabled') { is_expected.to be_denied_for(:admin) }
    it { is_expected.to be_allowed_for(:auditor) }
    it { is_expected.to be_allowed_for(:owner).of(project) }
    it { is_expected.to be_allowed_for(:maintainer).of(project) }
    it { is_expected.to be_allowed_for(:developer).of(project) }
    it { is_expected.to be_allowed_for(:reporter).of(project) }
    it { is_expected.to be_allowed_for(:guest).of(project) }
    it { is_expected.to be_denied_for(:user) }
    it { is_expected.to be_denied_for(:external) }
    it { is_expected.to be_denied_for(:visitor) }
  end

  describe "GET /:project_path" do
    subject { project_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/tree/master" do
    subject { project_tree_path(project, project.repository.root_ref) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/commits/master" do
    subject { project_commits_path(project, project.repository.root_ref, limit: 1) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/commit/:sha" do
    subject { project_commit_path(project, project.repository.commit) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/compare" do
    subject { project_compare_index_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/project_members" do
    subject { project_project_members_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/blob" do
    let(:commit) { project.repository.commit }

    subject { project_blob_path(project, File.join(commit.id, '.gitignore')) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/edit" do
    subject { edit_project_path(project) }

    it { is_expected.to be_denied_for(:auditor) }
  end

  describe "GET /:project_path/deploy_keys" do
    subject { project_deploy_keys_path(project) }

    it { is_expected.to be_denied_for(:auditor) }
  end

  describe "GET /:project_path/issues" do
    subject { project_issues_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/snippets" do
    subject { project_snippets_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/merge_requests" do
    subject { project_merge_requests_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/branches" do
    subject { project_branches_path(project) }

    before do
      # Speed increase
      allow_any_instance_of(Project).to receive(:branches).and_return([])
    end

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/tags" do
    subject { project_tags_path(project) }

    before do
      # Speed increase
      allow_any_instance_of(Project).to receive(:tags).and_return([])
    end

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/settings/integrations" do
    subject { project_settings_integrations_path(project) }

    it { is_expected.to be_denied_for(:auditor) }
  end

  describe "GET /:project_path/-/environments" do
    subject { project_environments_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/environments/:id" do
    let(:environment) { create(:environment, project: project) }

    subject { project_environment_path(project, environment) }

    it { is_expected.to be_allowed_for(:auditor) }
  end

  describe "GET /:project_path/-/environments/new" do
    subject { new_project_environment_path(project) }

    it { is_expected.to be_denied_for(:auditor) }
  end

  context "when license blocks changes" do
    before do
      allow(License).to receive(:block_changes?).and_return(true)
    end

    describe "GET /:project_path/issues/new" do
      subject { new_project_issue_path(project) }

      it { is_expected.to be_denied_for(:maintainer).of(project) }
      it { is_expected.to be_denied_for(:reporter).of(project) }
      it { is_expected.to be_denied_for(:admin) }
      it { is_expected.to be_denied_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:auditor) }
      it { is_expected.to be_denied_for(:visitor) }
    end

    describe "GET /:project_path/-/merge_requests/new" do
      subject { project_new_merge_request_path(project) }

      it { is_expected.to be_denied_for(:maintainer).of(project) }
      it { is_expected.to be_denied_for(:reporter).of(project) }
      it { is_expected.to be_denied_for(:admin) }
      it { is_expected.to be_denied_for(:guest).of(project) }
      it { is_expected.to be_denied_for(:user) }
      it { is_expected.to be_denied_for(:auditor) }
      it { is_expected.to be_denied_for(:visitor) }
    end
  end

  describe "GET /:project_path/container_registry" do
    let(:container_repository) { create(:container_repository) }

    before do
      stub_container_registry_tags(repository: :any, tags: ['latest'])
      stub_container_registry_config(enabled: true)
      project.container_repositories << container_repository
    end

    subject { project_container_registry_index_path(project) }

    it { is_expected.to be_allowed_for(:auditor) }
  end
end
