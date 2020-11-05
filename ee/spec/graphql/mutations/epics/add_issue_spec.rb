# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Epics::AddIssue do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let(:user) { issue.author }
  let(:issue) { create(:issue, project: project) }

  subject(:mutation) { described_class.new(object: group, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        group_path: group.full_path,
        iid: epic.iid,
        issue_iid: issue.iid,
        project_path: project.full_path
      )
    end

    it_behaves_like 'permission level for epic mutation is correctly verified'

    context 'when the user can update the epic' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)
      end

      it 'adds the issue to the epic' do
        expect(subject[:epic_issue]).to eq(issue)
        expect(subject[:epic_issue].epic).to eq(epic)
        expect(issue.reload.epic).to eq(epic)
        expect(subject[:errors]).to be_empty
      end

      it 'returns error if the issue is already assigned to the epic' do
        issue.update!(epic: epic)

        expect(subject[:errors]).to eq('Issue(s) already assigned')
      end

      it 'returns error if issue is not found' do
        issue.update!(project: create(:project))

        expect(subject[:errors]).to eq('No Issue found for given params')
      end
    end
  end
end
