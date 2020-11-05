# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::BuildService do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let(:user) { developer }

  before do
    project.add_developer(developer)
    project.add_guest(guest)
  end

  def build_issue(issue_params = {})
    described_class.new(project, user, issue_params).execute
  end

  context 'with an issue template' do
    describe '#execute' do
      let(:project) { build(:project, issues_template: 'Work hard, play hard!') }

      it 'fills in the template in the description' do
        issue = build_issue

        expect(issue.description).to eq('Work hard, play hard!')
      end
    end
  end

  context 'for a single thread' do
    describe '#execute' do
      let(:merge_request) { create(:merge_request, title: "Hello world", source_project: project) }
      let(:discussion) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, note: "Almost done").to_discussion }

      context 'with an issue template' do
        let(:project) { create(:project, :repository, issues_template: 'Work hard, play hard!') }

        it 'picks the thread description over the issue template' do
          issue = build_issue(
            merge_request_to_resolve_discussions_of: merge_request.iid,
            discussion_to_resolve: discussion.id
          )

          expect(issue.description).to include('Almost done')
        end
      end
    end
  end

  describe '#execute' do
    context 'as developer' do
      it 'sets test_case' do
        issue = build_issue(issue_type: 'test_case')

        expect(issue).to be_test_case
      end
    end

    context 'as guest' do
      let(:user) { guest }

      context 'setting issue type' do
        it 'cannot set test_case' do
          issue = build_issue(issue_type: 'test_case')

          expect(issue).to be_issue
        end
      end
    end
  end
end
