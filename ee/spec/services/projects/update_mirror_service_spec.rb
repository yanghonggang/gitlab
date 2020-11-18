# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UpdateMirrorService do
  let(:project) do
    create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL, only_mirror_protected_branches: false)
  end

  subject(:service) { described_class.new(project, project.owner) }

  describe "#execute" do
    context 'unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does nothing' do
        expect(project).not_to receive(:fetch_mirror)

        result = service.execute

        expect(result[:status]).to eq(:success)
      end
    end

    it "fetches the upstream repository" do
      expect(project).to receive(:fetch_mirror)

      service.execute
    end

    it 'runs project housekeeping' do
      stub_fetch_mirror(project)

      expect_next_instance_of(Projects::HousekeepingService) do |svc|
        expect(svc.project).to eq(project)
        expect(svc).to receive(:increment!)
        expect(svc).to receive(:needed?).and_return(true)
        expect(svc).to receive(:execute)
      end

      service.execute
    end

    it 'rescues exceptions from Repository#ff_merge' do
      stub_fetch_mirror(project)

      expect(project.repository).to receive(:ff_merge).and_raise(Gitlab::Git::PreReceiveError)

      expect { service.execute }.not_to raise_error
    end

    it "returns success when updated succeeds" do
      stub_fetch_mirror(project)

      result = service.execute

      expect(result[:status]).to eq(:success)
    end

    it "disables mirroring protected branches only by default" do
      new_project = create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL)

      expect(new_project.only_mirror_protected_branches).to be_falsey
    end

    context 'when mirror user is blocked' do
      before do
        project.mirror_user.block
      end

      it 'fails and returns error status' do
        expect(service.execute[:status]).to eq(:error)
      end
    end

    context "when the URL is blocked" do
      before do
        allow(Gitlab::UrlBlocker).to receive(:blocked_url?).and_return(true)

        stub_fetch_mirror(project)
      end

      it "fails and returns error status" do
        expect(service.execute[:status]).to eq(:error)
      end
    end

    context "when given URLs containing escaped elements" do
      it_behaves_like "URLs containing escaped elements return expected status" do
        let(:result) { service.execute }

        before do
          allow(project).to receive(:import_url).and_return(url)

          stub_fetch_mirror(project)
        end
      end
    end

    context "updating tags" do
      it "creates new tags" do
        stub_fetch_mirror(project)

        service.execute

        expect(project.repository.tag_names).to include('new-tag')
      end

      it "only invokes Git::TagPushService for tags pointing to commits" do
        stub_fetch_mirror(project)

        expect(Git::TagPushService).to receive(:new)
          .with(project, project.owner, change: hash_including(ref: 'refs/tags/new-tag'), mirror_update: true)
          .and_return(double(execute: true))

        service.execute
      end
    end

    context 'when repository is in read-only mode' do
      before do
        project.update_attribute(:repository_read_only, true)
      end

      it 'does not run if repository is set to read-only' do
        expect(service).not_to receive(:update_tags)
        expect(service).not_to receive(:update_branches)

        expect(service.execute).to be_truthy
      end
    end

    context 'when tags on mirror are modified' do
      let(:mirror_project) { create(:project, :repository)}
      let(:mirror_path) { File.join(TestEnv.repos_path, mirror_project.repository.relative_path) }
      let(:mirror_rugged) { Rugged::Repository.new(mirror_path) }
      let!(:mirror_modified_tag_sha) { modify_tag(mirror_project.repository, 'v1.0.0') }
      let!(:mirror_modified_branch_sha) { modify_branch(mirror_project.repository, 'feature') }
      let(:project) do
        create(:project, :repository, :mirror, import_url: Project::UNKNOWN_IMPORT_URL, only_mirror_protected_branches: false)
      end

      before do
        allow(project).to receive(:import_url).and_return(mirror_path)

        allow(Gitlab::UrlBlocker).to receive(:blocked_url?).and_return(false)
      end

      context 'when mirror_overwrites_diverged_branches is true' do
        before do
          project.mirror_overwrites_diverged_branches = true
        end

        it 'updates the tag' do
          result = service.execute

          expect(result[:status]).to eq(:success)
          expect(project.repository.find_tag('v1.0.0').dereferenced_target.id).to eq(mirror_modified_tag_sha)
        end

        it 'updates the modified branch' do
          service.execute

          expect(project.repository.find_branch('feature').dereferenced_target.id).to eq(mirror_modified_branch_sha)
        end

        it 'returns success' do
          result = service.execute

          expect(result[:status]).to eq(:success)
        end
      end

      context 'when mirror_overwrites_diverged_branches is false' do
        let(:error_message) { "Fetching remote upstream failed" }

        before do
          project.mirror_overwrites_diverged_branches = false
        end

        it 'updates the tag' do
          result = service.execute

          expect(result[:status]).to eq(:success)
          expect(project.repository.find_tag('v1.0.0').dereferenced_target.id).to eq(mirror_modified_tag_sha)
        end

        it 'does not update the modified branch' do
          service.execute

          expect(project.repository.find_branch('feature').dereferenced_target.id).not_to eq(mirror_modified_branch_sha)
        end

        it 'returns success' do
          result = service.execute

          expect(result[:status]).to eq(:success)
        end
      end
    end

    context 'updating branches' do
      shared_examples 'a working pull mirror' do |branch_prefix|
        context 'when the mirror has a repository' do
          let(:master) { "#{branch_prefix}master"}

          before do
            stub_fetch_mirror(project)
          end

          it 'creates new branches' do
            service.execute

            expect(project.repository.branch_names).to include("#{branch_prefix}new-branch")
          end

          it 'updates existing branches' do
            service.execute

            expect(project.repository.find_branch("#{branch_prefix}existing-branch").dereferenced_target)
              .to eq(project.repository.find_branch(master).dereferenced_target)
          end

          context 'when mirror only protected branches option is set' do
            let(:new_protected_branch_name) { "#{branch_prefix}new-branch" }
            let(:protected_branch_name) { "#{branch_prefix}existing-branch" }

            before do
              project.update!(only_mirror_protected_branches: true)
            end

            it 'creates a new protected branch' do
              create(:protected_branch, project: project, name: new_protected_branch_name)
              project.reload

              service.execute

              expect(project.repository.branch_names).to include(new_protected_branch_name)
            end

            it 'does not create an unprotected branch' do
              service.execute

              expect(project.repository.branch_names).not_to include(new_protected_branch_name)
            end

            it 'updates existing protected branches' do
              create(:protected_branch, project: project, name: protected_branch_name)
              project.reload

              service.execute

              expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
                .to eq(project.repository.find_branch(master).dereferenced_target)
            end

            it 'does not update unprotected branches' do
              service.execute

              expect(project.repository.find_branch(protected_branch_name).dereferenced_target)
                .not_to eq(project.repository.find_branch(master).dereferenced_target)
            end
          end

          context 'with diverged branches' do
            let(:diverged_branch) { "#{branch_prefix}markdown"}

            context 'when mirror_overwrites_diverged_branches is true' do
              it 'update diverged branches' do
                project.mirror_overwrites_diverged_branches = true

                service.execute

                expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                  .to eq(project.repository.find_branch(master).dereferenced_target)
              end
            end

            context 'when mirror_overwrites_diverged_branches is false' do
              it "doesn't update diverged branches" do
                project.mirror_overwrites_diverged_branches = false

                service.execute

                expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                  .not_to eq(project.repository.find_branch(master).dereferenced_target)
              end
            end

            context 'when mirror_overwrites_diverged_branches is nil' do
              it "doesn't update diverged branches" do
                project.mirror_overwrites_diverged_branches = nil

                service.execute

                expect(project.repository.find_branch(diverged_branch).dereferenced_target)
                  .not_to eq(project.repository.find_branch(master).dereferenced_target)
              end
            end
          end
        end

        context 'when project is empty' do
          it 'does not add a default master branch' do
            project    = create(:project_empty_repo, :mirror, import_url: Project::UNKNOWN_IMPORT_URL)
            repository = project.repository

            allow(project).to receive(:fetch_mirror) { create_file(repository) }
            expect(::Branches::CreateService).not_to receive(:create_master_branch)

            service.execute

            expect(repository.branch_names).not_to include('master')
          end
        end
      end

      context 'when pull_mirror_branch_prefix is set' do
        let(:pull_mirror_branch_prefix) { 'upstream/' }

        before do
          project.update!(pull_mirror_branch_prefix: pull_mirror_branch_prefix)
        end

        it "doesn't create unprefixed branches" do
          stub_fetch_mirror(project)

          service.execute

          expect(project.repository.branch_names).not_to include('new-branch')
        end

        it_behaves_like 'a working pull mirror', 'upstream/'

        context 'when pull_mirror_branch_prefix feature flag is disabled' do
          before do
            stub_feature_flags(pull_mirror_branch_prefix: false)
          end

          it_behaves_like 'a working pull mirror'

          it "doesn't create prefixed branches" do
            stub_fetch_mirror(project)

            service.execute

            expect(project.repository.branch_names).not_to include("#{pull_mirror_branch_prefix}new-branch")
          end
        end
      end

      it_behaves_like 'a working pull mirror'

      def create_file(repository)
        repository.create_file(
          project.owner,
          '/newfile.txt',
          'hello',
          message: 'Add newfile.txt',
          branch_name: 'newbranch'
        )
      end
    end

    context 'updating LFS objects' do
      context 'when repository does not change' do
        before do
          allow(project).to receive(:lfs_enabled?).and_return(true)
        end

        it 'does not attempt to update LFS objects' do
          expect(Projects::LfsPointers::LfsImportService).not_to receive(:new)

          service.execute
        end
      end

      context 'when repository changes' do
        before do
          stub_fetch_mirror(project)
        end

        context 'when Lfs is disabled in the project' do
          it 'does not update LFS objects' do
            allow(project).to receive(:lfs_enabled?).and_return(false)
            expect(Projects::LfsPointers::LfsObjectDownloadListService).not_to receive(:new)

            service.execute
          end
        end

        context 'when Lfs is enabled in the project' do
          before do
            allow(project).to receive(:lfs_enabled?).and_return(true)
          end

          it 'updates LFS objects' do
            expect(Projects::LfsPointers::LfsImportService).to receive(:new).and_call_original
            expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
              expect(instance).to receive(:execute).and_return({})
            end

            service.execute
          end

          context 'when Lfs import fails' do
            let(:error_message) { 'error_message' }

            before do
              expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |instance|
                expect(instance).to receive(:execute).and_return(status: :error, message: error_message)
              end
            end

            # Uncomment once https://gitlab.com/gitlab-org/gitlab-foss/issues/61834 is closed
            # it 'fails mirror operation' do
            #   expect_any_instance_of(Projects::LfsPointers::LfsImportService).to receive(:execute).and_return(status: :error, message: 'error message')

            #   result = subject.execute

            #   expect(result[:status]).to eq :error
            #   expect(result[:message]).to eq 'error message'
            # end

            # Remove once https://gitlab.com/gitlab-org/gitlab-foss/issues/61834 is closed
            it 'does not fail mirror operation' do
              result = subject.execute

              expect(result[:status]).to eq :success
            end

            it 'logs the error' do
              expect_next_instance_of(Gitlab::UpdateMirrorServiceJsonLogger) do |instance|
                expect(instance).to receive(:error).with(hash_including(error_message: error_message))
              end

              subject.execute
            end
          end
        end
      end
    end

    it "fails when the mirror user doesn't have access" do
      stub_fetch_mirror(project)

      result = described_class.new(project, create(:user)).execute

      expect(result[:status]).to eq(:error)
    end

    it "fails when no user is present" do
      result = described_class.new(project, nil).execute

      expect(result[:status]).to eq(:error)
    end

    it "returns success when there is no mirror" do
      project = build_stubbed(:project)
      user    = create(:user)

      result = described_class.new(project, user).execute

      expect(result[:status]).to eq(:success)
    end
  end

  def rewrite_refs_as_pull_mirror(project)
    return unless project.pull_mirror_branch_prefix
    return unless Feature.enabled?(:pull_mirror_branch_prefix)

    repository = project.repository
    old_branches = repository.branches.each_with_object({}) do |branch, branches|
      branches[branch.name] = branch.dereferenced_target.id
    end

    rugged = rugged_repo(repository)
    old_branches.each do |name, target|
      mirrored_branch_ref = "refs/heads/#{project.pull_mirror_branch_prefix}#{name}"
      rugged.references.create(mirrored_branch_ref, target)
      rugged.head = mirrored_branch_ref if name == 'master'
      rugged.branches.delete(name)
    end

    repository.expire_branches_cache
    repository.branches
  end

  def stub_fetch_mirror(project, repository: project.repository)
    branch_prefix = project.pull_mirror_branch_prefix
    branch_prefix = '' unless Feature.enabled?(:pull_mirror_branch_prefix)

    rewrite_refs_as_pull_mirror(project)

    allow(project).to receive(:fetch_mirror) { fetch_mirror(repository, branch_prefix: branch_prefix) }
  end

  def fetch_mirror(repository, branch_prefix: '')
    rugged = rugged_repo(repository)
    masterrev = repository.find_branch("#{branch_prefix}master").dereferenced_target.id

    parentrev = repository.commit(masterrev).parent_id
    rugged.references.create("refs/heads/#{branch_prefix}existing-branch", parentrev)

    repository.expire_branches_cache
    repository.branches

    # New branch
    rugged.references.create('refs/remotes/upstream/new-branch', masterrev)

    # Updated existing branch
    rugged.references.create('refs/remotes/upstream/existing-branch', masterrev)

    # Diverged branch
    rugged.references.create('refs/remotes/upstream/markdown', masterrev)

    # New tag
    rugged.references.create('refs/tags/new-tag', masterrev)

    # New tag that point to a blob
    rugged.references.create('refs/tags/new-tag-on-blob', 'c74175afd117781cbc983664339a0f599b5bb34e')
  end

  def modify_tag(repository, tag_name)
    rugged = rugged_repo(repository)
    masterrev = repository.find_branch('master').dereferenced_target.id

    # Modify tag
    rugged.references.update("refs/tags/#{tag_name}", masterrev)
    repository.find_tag(tag_name).dereferenced_target.id
  end

  def modify_branch(repository, branch_name)
    rugged = rugged_repo(repository)
    masterrev = repository.find_branch('master').dereferenced_target.id

    # Modify branch
    rugged.references.update("refs/heads/#{branch_name}", masterrev)
    repository.find_branch(branch_name).dereferenced_target.id
  end
end
