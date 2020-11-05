# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes filtering', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:user2)   { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:board) { create(:board, project: project) }

  let_it_be(:milestone) { create(:milestone, project: project) }

  let_it_be(:planning)    { create(:label, project: project, name: 'Planning', description: 'Test') }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:testing)     { create(:label, project: project, name: 'Testing') }
  let_it_be(:backlog)     { create(:label, project: project, name: 'Backlog') }
  let_it_be(:closed)      { create(:label, project: project, name: 'Closed') }
  let_it_be(:list1)       { create(:list, board: board, label: planning, position: 0) }
  let_it_be(:list2)       { create(:list, board: board, label: development, position: 1) }

  let_it_be(:confidential_issue) { create(:labeled_issue, :confidential, project: project, author: user, labels: [planning], relative_position: 9) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, title: 'aaa', description: '111', assignees: [user], labels: [planning], relative_position: 8) }
  let_it_be(:issue2) { create(:labeled_issue, project: project, title: 'bbb', description: '222', author: user2, labels: [planning], relative_position: 7) }
  let_it_be(:issue3) { create(:labeled_issue, project: project, title: 'ccc', description: '333', labels: [planning, testing], relative_position: 6) }
  let_it_be(:issue4) { create(:labeled_issue, project: project, title: 'ddd', description: '444', labels: [planning], relative_position: 5) }
  let_it_be(:issue5) { create(:labeled_issue, project: project, title: 'eee', description: '555', labels: [planning], milestone: milestone, relative_position: 4) }
  let_it_be(:issue6) { create(:labeled_issue, project: project, title: 'fff', description: '666', labels: [planning, development], relative_position: 3) }
  let_it_be(:issue7) { create(:labeled_issue, project: project, title: 'ggg', description: '777', labels: [development], relative_position: 2) }
  let_it_be(:issue8) { create(:closed_issue, project: project, title: 'hhh', description: '888') }

  context 'filtering' do
    before do
      project.add_maintainer(user)
      project.add_maintainer(user2)

      stub_licensed_features(epics: true, swimlanes: true)
      sign_in(user)
      visit_board_page

      page.within('.board-swimlanes-toggle-wrapper') do
        page.find('.dropdown-toggle').click
        page.find('.dropdown-item', text: 'Epic').click
      end

      wait_for_all_requests

      stub_const("Gitlab::QueryLimiting::Transaction::THRESHOLD", 200)
    end

    it 'filters by author' do
      wait_for_all_requests

      set_filter("author", user2.username)
      click_filter_link(user2.username)

      submit_filter

      wait_for_all_requests
      wait_for_board_cards(2, 1)
      wait_for_empty_boards((3..4))
    end

    it 'filters by assignee', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/266990' do
      wait_for_all_requests

      set_filter("assignee", user.username)
      click_filter_link(user.username)
      submit_filter

      wait_for_all_requests

      wait_for_board_cards(2, 1)
      wait_for_empty_boards((3..4))
    end

    it 'filters by milestone' do
      wait_for_all_requests

      set_filter("milestone", "\"#{milestone.title}")
      click_filter_link(milestone.title)
      submit_filter

      wait_for_all_requests

      wait_for_board_cards(2, 1)
      wait_for_board_cards(3, 0)
      wait_for_board_cards(4, 0)
    end

    it 'filters by label' do
      wait_for_all_requests

      set_filter("label", testing.title)
      click_filter_link(testing.title)
      submit_filter

      wait_for_all_requests

      wait_for_board_cards(2, 1)
      wait_for_empty_boards((3..4))
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_all_requests
  end

  def wait_for_board_cards(board_number, expected_cards)
    page.within(find(".board-swimlanes-headers .board:nth-child(#{board_number})")) do
      expect(page.find('.board-header')).to have_content(expected_cards.to_s)
    end

    page.within(find("[data-testid='board-lane-unassigned-issues'] .board:nth-child(#{board_number})")) do
      expect(page).to have_selector('.board-card', count: expected_cards)
    end
  end

  def wait_for_empty_boards(board_numbers)
    board_numbers.each do |board|
      wait_for_board_cards(board, 0)
    end
  end

  def set_filter(type, text)
    find('.filtered-search').native.send_keys("#{type}:=#{text}")
  end

  def submit_filter
    find('.filtered-search').native.send_keys(:enter)
  end

  def click_filter_link(link_text)
    page.within('.filtered-search-box') do
      expect(page).to have_button(link_text)

      click_button(link_text)
    end
  end
end
