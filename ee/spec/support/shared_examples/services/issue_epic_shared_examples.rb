# frozen_string_literal: true

RSpec.shared_examples 'issue with epic_id parameter' do
  before do
    stub_licensed_features(epics: true)
  end

  context 'when epic_id does not exist' do
    let(:params) { { title: 'issue1', epic_id: -1 } }

    it 'raises an exception' do
      expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'when epic_id is 0' do
    let(:params) { { title: 'issue1', epic_id: 0 } }

    it 'does not assign any epic' do
      issue = execute

      expect(issue.reload).to be_persisted
      expect(issue.epic).to be_nil
    end
  end

  context 'when user can not add issues to the epic' do
    before do
      project.add_maintainer(user)
    end

    let(:params) { { title: 'issue1', epic_id: epic.id } }

    it 'raises an exception' do
      expect { execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  context 'when user can add issues to the epic' do
    before do
      group.add_maintainer(user)
      project.add_maintainer(user)
    end

    let(:params) { { title: 'issue1', epic_id: epic.id } }

    context 'when a project is a direct child of the epic group' do
      it 'creates epic issue link' do
        issue = execute

        expect(issue.reload).to be_persisted
        expect(issue.epic).to eq(epic)
      end

      it 'calls EpicIssues::CreateService' do
        link_sevice = double
        expect(EpicIssues::CreateService).to receive(:new).and_return(link_sevice)
        expect(link_sevice).to receive(:execute).and_return({ status: :success })

        execute
      end
    end

    context 'when epic param is also present' do
      context 'when epic_id belongs to another valid epic' do
        let(:other_epic) { create(:epic, group: group) }
        let(:params) { { title: 'issue1', epic: epic, epic_id: other_epic.id } }

        it 'creates epic issue link based on the epic param' do
          issue = execute

          expect(issue.reload).to be_persisted
          expect(issue.epic).to eq(epic)
        end
      end

      context 'when epic_id is empty' do
        let(:params) { { title: 'issue1', epic: epic, epic_id: '' } }

        it 'creates epic issue link based on the epic param' do
          issue = execute

          expect(issue.reload).to be_persisted
          expect(issue.epic).to eq(epic)
        end
      end
    end

    context 'when a project is from a subgroup of the epic group' do
      before do
        subgroup = create(:group, parent: group)
        create(:epic, group: subgroup)
        project.update!(group: subgroup)
      end

      it 'creates epic issue link' do
        issue = execute

        expect(issue.reload).to be_persisted
        expect(issue.epic).to eq(epic)
      end
    end
  end
end
