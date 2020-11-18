# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::CreatePipelineService do
  let(:project) { create(:project, :repository, :auto_devops) }
  let_it_be(:maintainer) { create(:user) }
  let(:service) { described_class.new(project, maintainer) }
  let(:previous_ref) { 'refs/heads/master' }

  before do
    project.add_maintainer(maintainer)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    stub_feature_flags(ci_disallow_to_create_merge_request_pipelines_in_target_project: false)
    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
  end

  describe '#execute' do
    subject { service.execute(merge_request, previous_ref) }

    let!(:merge_request) do
      create(:merge_request, :on_train, train_creator: maintainer,
        source_branch: 'feature', source_project: project,
        target_branch: 'master', target_project: project,
        merge_status: 'unchecked')
    end

    shared_examples_for 'returns an error' do
      let(:expected_reason) { 'unknown' }

      specify do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to match(/^#{expected_reason}/)
      end
    end

    context 'when merge trains flag is disabled' do
      before do
        stub_feature_flags(disable_merge_trains: true)
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'merge trains is disabled' }
      end
    end

    context 'when merge trains setting is disabled' do
      before do
        project.update!(merge_trains_enabled: false)
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'merge trains is disabled' }
      end
    end

    context 'when merge request is not on a merge train' do
      let!(:merge_request) do
        create(:merge_request,
          source_branch: 'feature', source_project: project,
          target_branch: 'master', target_project: project)
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'merge request is not on a merge train' }
      end
    end

    context 'when merge request is submitted from a forked project' do
      context 'when ci_disallow_to_create_merge_request_pipelines_in_target_project feature flag is enabled' do
        before do
          stub_feature_flags(ci_disallow_to_create_merge_request_pipelines_in_target_project: true)
          allow(merge_request).to receive(:for_same_project?) { false }
        end

        it_behaves_like 'returns an error' do
          let(:expected_reason) { 'this merge request cannot be added to merge train' }
        end
      end
    end

    context 'when prepared merge ref successfully' do
      context 'when .gitlab-ci.yml has only: [merge_requests] specification' do
        let(:ci_yaml) do
          { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
        end

        before do
          stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
        end

        it 'creates train ref' do
          expect { subject }
            .to change { merge_request.project.repository.ref_exists?(merge_request.train_ref_path) }
            .from(false).to(true)

          expect(project.repository.commit(merge_request.train_ref_path).message)
            .to eq("Merge branch #{merge_request.source_branch} with #{previous_ref} " \
                   "into #{merge_request.train_ref_path}")
        end

        it 'calls Ci::CreatePipelineService for creating pipeline on train ref' do
          expect_next_instance_of(Ci::CreatePipelineService, project, maintainer, hash_including(ref: merge_request.train_ref_path)) do |pipeline_service|
            expect(pipeline_service).to receive(:execute)
              .with(:merge_request_event, hash_including(merge_request: merge_request)).and_call_original
          end

          subject
        end

        context 'when previous_ref is a train ref' do
          let(:previous_ref) { 'refs/merge-requests/999/train' }
          let(:previous_ref_sha) { project.repository.commit('refs/merge-requests/999/train').sha }

          context 'when previous_ref exists' do
            before do
              project.repository.create_ref('master', previous_ref)
            end

            it 'creates train ref with the specified ref' do
              subject

              commit = project.repository.commit(merge_request.train_ref_path)
              expect(commit.parent_ids[1]).to eq(merge_request.diff_head_sha)
              expect(commit.parent_ids[0]).to eq(previous_ref_sha)
            end
          end

          context 'when previous_ref does not exist' do
            it_behaves_like 'returns an error' do
              let(:expected_reason) { '3:Invalid merge source' }
            end
          end

          context 'when there is a conflict on merge ref creation' do
            before do
              allow(project.repository).to receive(:merge_to_ref) do
                raise Gitlab::Git::CommandError.new('Failed to create merge commit')
              end
            end

            it_behaves_like 'returns an error' do
              let(:expected_reason) { 'Failed to create merge commit' }
            end
          end
        end

        context 'when previous_ref is nil' do
          let(:previous_ref) { nil }

          it_behaves_like 'returns an error' do
            let(:expected_reason) { 'previous ref is not specified' }
          end
        end
      end

      context 'when .gitlab-ci.yml does not have only: [merge_requests] specification' do
        it_behaves_like 'returns an error' do
          let(:expected_reason) { 'No stages / jobs for this pipeline.' }
        end
      end
    end

    context 'when failed to prepare merge ref' do
      before do
        check_service = double
        allow(::MergeRequests::MergeToRefService).to receive(:new) { check_service }
        allow(check_service).to receive(:execute) { { status: :error, message: 'Merge ref was not found' } }
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'Merge ref was not found' }
      end
    end
  end
end
