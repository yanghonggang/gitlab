# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR' do
  include ProjectForksHelper

  before do
    stub_licensed_features(multiple_merge_request_assignees: false)
  end

  context 'non-fork merge request' do
    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request'
  end

  context 'for a forked project' do
    let(:source_project) { fork_project(target_project, nil, repository: true) }

    include_context 'merge request edit context'
    it_behaves_like 'an editable merge request'
  end

  context 'approval rules', :js do
    let(:mr_rule_name) { 'some-custom-rule' }
    let(:user) { create(:admin) }
    let(:source_project) { fork_project(target_project, nil, repository: true) }
    let(:merge_request) { create(:merge_request, author: user, source_project: source_project) }
    let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: [user], name: mr_rule_name, approvals_required: 1 )}

    include_context 'merge request edit context'

    # it 'is shown in reviewer dropdown' do
    #   find('.js-reviewer-search').click

    #   page.within '.dropdown-menu-reviewer' do
    #     binding.pry
    #     expect(page).to have_content(mr_rule_name)
    #   end
    # end

    it 'is not shown in assignee dropdown', :js do
      find('.js-assignee-search').click

      page.within '.dropdown-menu-assignee' do
        expect(page).not_to have_content(mr_rule_name)
      end
    end
  end

  context 'when merge_request_reviewers is turned off' do
    before do
      stub_feature_flags(merge_request_reviewers: false)
    end

    it 'does not render reviewers dropdown' do
      expect(page).not_to have_selector('.js-reviewer-search')
    end
  end
end
