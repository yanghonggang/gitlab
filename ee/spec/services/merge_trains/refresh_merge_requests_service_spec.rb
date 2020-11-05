# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::RefreshMergeRequestsService do
  include ExclusiveLeaseHelpers

  let(:project) { create(:project) }
  let_it_be(:maintainer_1) { create(:user) }
  let_it_be(:maintainer_2) { create(:user) }
  let(:service) { described_class.new(project, maintainer_1) }

  before do
    project.add_maintainer(maintainer_1)
    project.add_maintainer(maintainer_2)
  end

  describe '#execute', :clean_gitlab_redis_queues do
    subject { service.execute(merge_request) }

    let!(:merge_request_1) do
      create(:merge_request, :on_train, train_creator: maintainer_1,
        source_branch: 'feature', source_project: project,
        target_branch: 'master', target_project: project)
    end

    let!(:merge_request_2) do
      create(:merge_request, :on_train, train_creator: maintainer_2,
        source_branch: 'signed-commits', source_project: project,
        target_branch: 'master', target_project: project)
    end

    let(:refresh_service_1) { double }
    let(:refresh_service_2) { double }
    let(:refresh_service_1_result) { { status: :success } }
    let(:refresh_service_2_result) { { status: :success } }

    before do
      allow(MergeTrains::RefreshMergeRequestService)
        .to receive(:new).with(project, maintainer_1, anything) { refresh_service_1 }
      allow(MergeTrains::RefreshMergeRequestService)
        .to receive(:new).with(project, maintainer_2, anything) { refresh_service_2 }

      allow(refresh_service_1).to receive(:execute) { refresh_service_1_result }
      allow(refresh_service_2).to receive(:execute) { refresh_service_2_result }
    end

    shared_examples 'logging results' do |count|
      context 'when ci_merge_train_logging is enabled' do
        it 'logs results' do
          expect(Sidekiq.logger).to receive(:info).exactly(count).times

          subject
        end
      end

      context 'when ci_merge_train_logging is disabled' do
        before do
          stub_feature_flags(ci_merge_train_logging: false)
        end

        it 'does not log results' do
          expect(Sidekiq.logger).not_to receive(:info)

          subject
        end
      end
    end

    context 'when merge request 1 is passed' do
      let(:merge_request) { merge_request_1 }

      it 'executes RefreshMergeRequestService to all the following merge requests' do
        expect(refresh_service_1).to receive(:execute).with(merge_request_1)
        expect(refresh_service_2).to receive(:execute).with(merge_request_2)

        subject
      end

      it_behaves_like 'logging results', 3

      context 'when refresh service 1 returns error status' do
        let(:refresh_service_1_result) { { status: :error, message: 'Failed to create ref' } }

        it 'specifies require_recreate to refresh service 2' do
          allow(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: true) { refresh_service_2 }

          subject
        end

        it_behaves_like 'logging results', 3
      end

      context 'when refresh service 1 returns success status and did not create a pipeline' do
        let(:refresh_service_1_result) { { status: :success, pipeline_created: false } }

        it 'does not specify require_recreate to refresh service 2' do
          allow(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: false) { refresh_service_2 }

          subject
        end

        it_behaves_like 'logging results', 3
      end

      context 'when refresh service 1 returns success status and created a pipeline' do
        let(:refresh_service_1_result) { { status: :success, pipeline_created: true } }

        it 'specifies require_recreate to refresh service 2' do
          allow(MergeTrains::RefreshMergeRequestService)
            .to receive(:new).with(project, maintainer_2, require_recreate: true) { refresh_service_2 }

          subject
        end

        it_behaves_like 'logging results', 3
      end

      context 'when merge request 1 is not on a merge train' do
        let(:merge_request) { merge_request_1 }
        let!(:merge_request_1) { create(:merge_request) }

        it 'does not refresh' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)

          subject
        end

        it_behaves_like 'logging results', 0
      end

      context 'when merge request 1 was on a merge train' do
        before do
          allow(merge_request_1.merge_train).to receive(:cleanup_ref)
          merge_request_1.merge_train.update_column(:status, MergeTrain.state_machines[:status].states[:merged].value)
        end

        it 'does not refresh' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)

          subject
        end

        it_behaves_like 'logging results', 0
      end

      context 'when the other thread has already been processing the merge train' do
        let(:lock_key) { "batch_pop_queueing:lock:merge_trains:#{merge_request.target_project_id}:#{merge_request.target_branch}" }

        before do
          stub_exclusive_lease_taken(lock_key)
        end

        it 'does not refresh' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)

          subject
        end

        it 'enqueues the merge request id to BatchPopQueueing' do
          expect_next_instance_of(Gitlab::BatchPopQueueing) do |queuing|
            expect(queuing).to receive(:enqueue).with([merge_request_1.id], anything).and_call_original
          end

          subject
        end

        it_behaves_like 'logging results', 1
      end
    end

    context 'when merge request 2 is passed' do
      let(:merge_request) { merge_request_2 }

      it 'executes RefreshMergeRequestService to all the merge requests from beginning' do
        expect(refresh_service_1).to receive(:execute).with(merge_request_1)
        expect(refresh_service_2).to receive(:execute).with(merge_request_2)

        subject
      end

      context 'when ci_always_refresh_merge_requests_from_beginning is disabled' do
        before do
          stub_feature_flags(ci_always_refresh_merge_requests_from_beginning: false)
        end

        it 'executes RefreshMergeRequestService to all the following merge requests' do
          expect(refresh_service_1).not_to receive(:execute).with(merge_request_1)
          expect(refresh_service_2).to receive(:execute).with(merge_request_2)

          subject
        end

        context 'when merge request 1 was tried to be refreshed while the system is refreshing merge request 2' do
          before do
            allow_any_instance_of(described_class).to receive(:unsafe_refresh).with(merge_request_2) do
              service.execute(merge_request_1)
            end
          end

          it 'refreshes the merge request 1 later with AutoMergeProcessWorker' do
            expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request_1.id).once

            subject
          end

          context 'when ci_always_refresh_merge_requests_from_beginning is disabled' do
            before do
              stub_feature_flags(ci_always_refresh_merge_requests_from_beginning: false)
            end

            it 'refreshes the merge request 1 later with AutoMergeProcessWorker' do
              expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request_1.id).once

              subject
            end
          end

          it_behaves_like 'logging results', 4

          context 'when merge request 1 has already been merged' do
            before do
              allow(merge_request_1.merge_train).to receive(:cleanup_ref)
              merge_request_1.merge_train.update_column(:status, MergeTrain.state_machines[:status].states[:merged].value)
            end

            it 'does not refresh the merge request 1' do
              expect(AutoMergeProcessWorker).not_to receive(:perform_async).with(merge_request_1.id)

              subject
            end

            it_behaves_like 'logging results', 1
          end
        end
      end

      it_behaves_like 'logging results', 3
    end
  end
end
