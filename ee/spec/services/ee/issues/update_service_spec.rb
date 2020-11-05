# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::UpdateService do
  let_it_be(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { issue.author }

  describe 'execute' do
    before do
      project.add_reporter(user)
    end

    def update_issue(opts)
      described_class.new(project, user, opts).execute(issue)
    end

    context 'refresh epic dates' do
      let_it_be(:epic) { create(:epic) }
      let(:issue) { create(:issue, epic: epic, project: project) }

      context 'updating milestone' do
        let(:milestone) { create(:milestone, project: project) }

        it 'calls UpdateDatesService' do
          expect(Epics::UpdateDatesService).to receive(:new).with([epic]).and_call_original.twice

          update_issue(milestone: milestone)
          update_issue(milestone_id: nil)
        end
      end

      context 'updating iteration' do
        let(:iteration) { create(:iteration, group: group) }

        context 'when issue does not already have an iteration' do
          it 'calls NotificationService#changed_iteration_issue' do
            expect_next_instance_of(NotificationService::Async) do |ns|
              expect(ns).to receive(:changed_iteration_issue)
            end

            update_issue(iteration: iteration)
          end
        end

        context 'when issue already has an iteration' do
          let(:old_iteration) { create(:iteration, group: group) }

          before do
            update_issue(iteration: old_iteration)
          end

          context 'setting to nil' do
            it 'calls NotificationService#removed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:removed_iteration_issue)
              end

              update_issue(iteration: nil)
            end
          end

          context 'setting to another iteration' do
            it 'calls NotificationService#changed_iteration_issue' do
              expect_next_instance_of(NotificationService::Async) do |ns|
                expect(ns).to receive(:changed_iteration_issue)
              end

              update_issue(iteration: iteration)
            end
          end
        end
      end

      context 'updating weight' do
        before do
          project.add_maintainer(user)
          issue.update(weight: 3)
        end

        context 'when weight is integer' do
          it 'updates to the exact value' do
            expect { update_issue(weight: 2) }.to change { issue.weight }.to(2)
          end
        end

        context 'when weight is float' do
          it 'rounds the value down' do
            expect { update_issue(weight: 1.8) }.to change { issue.weight }.to(1)
          end
        end

        context 'when weight is zero' do
          it 'sets the value to zero' do
            expect { update_issue(weight: 0) }.to change { issue.weight }.to(0)
          end
        end

        context 'when weight is a string' do
          it 'sets the value to 0' do
            expect { update_issue(weight: 'abc') }.to change { issue.weight }.to(0)
          end
        end
      end

      it_behaves_like 'updating issuable health status' do
        let(:issuable) { issue }
        let(:parent) { project }
      end

      context 'updating other fields' do
        it 'does not call UpdateDatesService' do
          expect(Epics::UpdateDatesService).not_to receive(:new)
          update_issue(title: 'foo')
        end
      end
    end

    context 'assigning iteration' do
      before do
        stub_licensed_features(iterations: true)
        group.add_maintainer(user)
      end

      RSpec.shared_examples 'creates iteration resource event' do
        it 'creates a system note' do
          expect do
            update_issue(iteration: iteration)
          end.not_to change { Note.system.count }
        end

        it 'does not create a iteration change event' do
          expect do
            update_issue(iteration: iteration)
          end.to change { ResourceIterationEvent.count }.by(1)
        end
      end

      context 'group iterations' do
        let(:iteration) { create(:iteration, group: group) }

        it_behaves_like 'creates iteration resource event'
      end

      context 'project iterations' do
        let(:iteration) { create(:iteration, :skip_project_validation, project: project) }

        it_behaves_like 'creates iteration resource event'
      end
    end

    context 'assigning epic' do
      before do
        stub_licensed_features(epics: true)
      end

      let(:epic) { create(:epic, group: group) }

      subject { update_issue(epic: epic) }

      context 'when a user does not have permissions to assign an epic' do
        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_maintainer(user)
        end

        context 'when issue does not belong to an epic yet' do
          it 'assigns an issue to the provided epic' do
            expect { update_issue(epic: epic) }.to change { issue.reload.epic }.from(nil).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end
        end

        context 'when issue belongs to another epic' do
          let(:epic2) { create(:epic, group: group) }

          before do
            issue.update!(epic: epic2)
          end

          it 'assigns the issue passed to the provided epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic2).to(epic)
          end

          it 'calls EpicIssues::CreateService' do
            link_sevice = double
            expect(EpicIssues::CreateService).to receive(:new)
              .with(epic, user, { target_issuable: issue, skip_epic_dates_update: true })
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end
        end
      end
    end

    context 'removing epic' do
      before do
        stub_licensed_features(epics: true)
      end

      let(:epic) { create(:epic, group: group) }

      subject { update_issue(epic: nil) }

      context 'when a user has permissions to assign an epic' do
        before do
          group.add_maintainer(user)
        end

        context 'when issue does not belong to an epic yet' do
          it 'does not do anything' do
            expect { subject }.not_to change { issue.reload.epic }
          end
        end

        context 'when issue belongs to an epic' do
          let!(:epic_issue) { create(:epic_issue, issue: issue, epic: epic)}

          it 'unassigns the epic' do
            expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
          end

          it 'calls EpicIssues::DestroyService' do
            link_sevice = double
            expect(EpicIssues::DestroyService).to receive(:new).with(EpicIssue.last, user)
              .and_return(link_sevice)
            expect(link_sevice).to receive(:execute).and_return({ status: :success })

            subject
          end
        end
      end
    end

    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { issue }
      let(:parent) { project }
    end

    it_behaves_like 'issue with epic_id parameter' do
      let(:execute) { described_class.new(project, user, params).execute(issue) }
      let(:epic) { create(:epic, group: group) }
    end

    context 'when epic_id is nil' do
      before do
        stub_licensed_features(epics: true)
        group.add_maintainer(user)
      end

      let(:epic) { create(:epic, group: group) }
      let!(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }
      let(:params) { { epic_id: nil } }

      subject { update_issue(params) }

      it 'removes epic issue link' do
        expect { subject }.to change { issue.reload.epic }.from(epic).to(nil)
      end

      it 'calls EpicIssues::DestroyService' do
        link_sevice = double
        expect(EpicIssues::DestroyService).to receive(:new).with(epic_issue, user)
          .and_return(link_sevice)
        expect(link_sevice).to receive(:execute).and_return({ status: :success })

        subject
      end
    end

    context 'promoting to epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)
      end

      context 'when promote_to_epic param is present' do
        it 'promotes issue to epic' do
          expect { update_issue(promote_to_epic: true) }.to change { Epic.count }.by(1)
          expect(issue.promoted_to_epic_id).not_to be_nil
        end
      end

      context 'when promote_to_epic param is not present' do
        it 'does not promote issue to epic' do
          expect { update_issue(promote_to_epic: false) }.not_to change { Epic.count }
          expect(issue.promoted_to_epic_id).to be_nil
        end
      end
    end

    describe 'publish to status page' do
      let(:execute) { update_issue(params) }
      let(:issue_id) { execute&.id }

      before do
        create(:status_page_published_incident, issue: issue)
      end

      context 'when update succeeds' do
        let(:params) { { title: 'New title' } }

        include_examples 'trigger status page publish'
      end

      context 'when closing' do
        let(:params) { { state_event: 'close' } }

        include_examples 'trigger status page publish'
      end

      context 'when reopening' do
        let(:issue) { create(:issue, :closed, project: project) }
        let(:params) { { state_event: 'reopen' } }

        include_examples 'trigger status page publish'
      end

      context 'when update fails' do
        let(:params) { { title: nil } }

        include_examples 'no trigger status page publish'
      end
    end
  end
end
