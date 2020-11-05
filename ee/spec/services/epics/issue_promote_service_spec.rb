# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Epics::IssuePromoteService, :aggregate_failures do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:label1) { create(:group_label, group: group) }
  let(:label2) { create(:label, project: project) }
  let(:milestone) { create(:milestone, group: group) }
  let(:description) { 'simple description' }
  let(:issue) do
    create(:issue, project: project, labels: [label1, label2],
                   milestone: milestone, description: description)
  end

  subject { described_class.new(issue.project, user) }

  let(:epic) { Epic.last }

  describe '#execute' do
    context 'when epics are not enabled' do
      it 'raises a permission error' do
        group.add_developer(user)

        expect { subject.execute(issue) }
          .to raise_error(Epics::IssuePromoteService::PromoteError, /permissions/)
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user can not promote the issue' do
        it 'raises a permission error' do
          expect { subject.execute(issue) }
            .to raise_error(Epics::IssuePromoteService::PromoteError, /permissions/)
        end
      end

      context 'when a user can promote the issue' do
        let(:new_group) { create(:group) }

        before do
          group.add_developer(user)
          new_group.add_developer(user)
        end

        context 'when an issue does not belong to a group' do
          it 'raises an error' do
            other_issue = create(:issue, project: create(:project))

            expect { subject.execute(other_issue) }
              .to raise_error(Epics::IssuePromoteService::PromoteError, /group/)
          end
        end

        context 'when promoting issue', :snowplow do
          let!(:issue_mentionable_note) { create(:note, noteable: issue, author: user, project: project, note: "note with mention #{user.to_reference}") }
          let!(:issue_note) { create(:note, noteable: issue, author: user, project: project, note: "note without mention") }

          before do
            allow(ProductAnalytics::Tracker).to receive(:event).with('epics', 'promote', an_instance_of(Hash))

            subject.execute(issue)

            expect_snowplow_event(category: 'epics', action: 'promote', property: 'issue_id', value: issue.id)
          end

          it 'creates a new epic with correct attributes' do
            expect(epic.title).to eq(issue.title)
            expect(epic.description).to eq(issue.description)
            expect(epic.author).to eq(user)
            expect(epic.group).to eq(group)
            expect(epic.parent).to be_nil
          end

          it 'copies group labels assigned to the issue' do
            expect(epic.labels).to eq([label1])
          end

          it 'creates a system note on the issue' do
            expect(issue.notes.last.note).to eq("promoted to epic #{epic.to_reference(project)}")
          end

          it 'creates a system note on the epic' do
            expect(epic.notes.last.note).to eq("promoted from issue #{issue.to_reference(group)}")
          end

          it 'closes the original issue' do
            expect(issue).to be_closed
          end

          it 'marks the old issue as promoted' do
            expect(issue).to be_promoted
            expect(issue.promoted_to_epic).to eq(epic)
          end

          context 'when issue description has mentions and has notes with mentions' do
            let(:issue) { create(:issue, project: project, description: "description with mention to #{user.to_reference}") }

            it 'only saves user mentions with actual mentions' do
              expect(epic.user_mentions.find_by(note_id: nil).mentioned_users_ids).to match_array([user.id])
              expect(epic.user_mentions.where.not(note_id: nil).first.mentioned_users_ids).to match_array([user.id])
              expect(epic.user_mentions.where.not(note_id: nil).count).to eq 1
              expect(epic.user_mentions.count).to eq 2
            end
          end

          context 'when issue description has an attachment' do
            let(:image_uploader) { build(:file_uploader, project: project) }
            let(:description) { "A description and image: #{image_uploader.markdown_link}" }

            it 'copies the description, rewriting the attachment' do
              new_image_uploader = Upload.last.retrieve_uploader

              expect(new_image_uploader.markdown_link).not_to eq(image_uploader.markdown_link)
              expect(epic.description).to eq("A description and image: #{new_image_uploader.markdown_link}")
            end
          end
        end

        context 'when promoting issue to a different group' do
          it 'creates a new epic with correct attributes' do
            epic = subject.execute(issue, new_group)

            expect(issue.reload.promoted_to_epic_id).to eq(epic.id)
            expect(epic.title).to eq(issue.title)
            expect(epic.description).to eq(issue.description)
            expect(epic.author).to eq(user)
            expect(epic.group).to eq(new_group)
            expect(epic.parent).to be_nil
          end
        end

        context 'when an issue belongs to an epic' do
          let(:parent_epic) { create(:epic, group: group) }
          let!(:epic_issue) { create(:epic_issue, epic: parent_epic, issue: issue) }

          it 'creates a new epic with correct attributes' do
            subject.execute(issue)

            expect(epic.title).to eq(issue.title)
            expect(epic.description).to eq(issue.description)
            expect(epic.author).to eq(user)
            expect(epic.group).to eq(group)
            expect(epic.parent).to eq(parent_epic)
          end

          context 'when promoting issue to a different group' do
            it 'creates a new epic with correct attributes' do
              expect { subject.execute(issue, new_group) }
                .to raise_error(StandardError, 'Validation failed: Parent This epic cannot be added. An epic must belong to the same group or subgroup as its parent epic.')

              expect(issue.reload.state).to eq("opened")
              expect(issue.reload.promoted_to_epic_id).to be_nil
            end
          end

          context 'when promoting issue to a different group in the hierarchy' do
            let(:new_group) { create(:group, parent: group) }

            before do
              new_group.add_developer(user)
            end

            it 'creates a new epic with correct attributes' do
              epic = subject.execute(issue, new_group)

              expect(issue.reload.promoted_to_epic_id).to eq(epic.id)
              expect(epic.title).to eq(issue.title)
              expect(epic.description).to eq(issue.description)
              expect(epic.author).to eq(user)
              expect(epic.group).to eq(new_group)
              expect(epic.parent).to eq(parent_epic)
            end
          end
        end

        context 'when issue was already promoted' do
          it 'raises error' do
            epic = create(:epic, group: group)
            issue.update(promoted_to_epic_id: epic.id)

            expect { subject.execute(issue) }
              .to raise_error(Epics::IssuePromoteService::PromoteError, /already promoted/)
          end
        end

        context 'when issue has notes', :snowplow do
          before do
            allow(ProductAnalytics::Tracker).to receive(:event).with('epics', 'promote', an_instance_of(Hash))
            issue.reload
          end

          it 'copies all notes' do
            discussion = create(:discussion_note_on_issue, noteable: issue, project: issue.project)

            epic = subject.execute(issue)
            expect(epic.notes.count).to eq(issue.notes.count)
            expect(epic.notes.where(discussion_id: discussion.discussion_id).count).to eq(0)
            expect(issue.notes.where(discussion_id: discussion.discussion_id).count).to eq(1)
            expect_snowplow_event(category: 'epics', action: 'promote', property: 'issue_id', value: issue.id)
          end

          it 'copies note attachments' do
            create(:discussion_note_on_issue, :with_attachment, noteable: issue, project: issue.project)

            epic = subject.execute(issue)

            expect(epic.notes.user.first.attachment).to be_kind_of(AttachmentUploader)
            expect_snowplow_event(category: 'epics', action: 'promote', property: 'issue_id', value: issue.id)
          end
        end

        context 'on other issue types' do
          shared_examples_for 'raising error' do
            before do
              issue.update(issue_type: issue_type)
            end

            it 'raises error' do
              expect { subject.execute(issue) }
                .to raise_error(Epics::IssuePromoteService::PromoteError, /is not supported/)
            end
          end

          context 'on an incident' do
            let(:issue_type) { :incident }

            it_behaves_like 'raising error'
          end

          context 'on a test case' do
            let(:issue_type) { :test_case }

            it_behaves_like 'raising error'
          end
        end
      end
    end
  end
end
