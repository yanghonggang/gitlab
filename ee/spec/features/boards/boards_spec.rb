# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'issue boards', :js do
  include DragTo

  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:board) { create(:board, project: project) }
  let(:milestone) { create(:milestone, title: "v2.2", project: project) }
  let!(:board_with_milestone) { create(:board, project: project, milestone: milestone) }

  context 'with group and reporter' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, namespace: group) }

    before do
      project.add_maintainer(user)
      group.add_reporter(user)
      login_as(user)
    end

    it 'can edit board name' do
      visit_board_page

      board_name = board.name
      new_board_name = board_name + '-Test'

      click_button 'Edit board'
      fill_in 'board-new-name', with: new_board_name
      click_button 'Save changes'

      expect(page).to have_content new_board_name
    end
  end

  context 'add list dropdown' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, namespace: group) }

    before do
      project.add_maintainer(user)
      group.add_reporter(user)
      login_as(user)
    end

    it 'shows tabbed dropdown with labels list and assignees list' do
      stub_licensed_features(board_assignee_lists: true)

      visit_board_page

      page.within('#js-add-list') do
        page.find('.js-new-board-list').click
        wait_for_requests
        expect(page).to have_css('.dropdown-menu.dropdown-menu-tabs')
        expect(page).to have_css('.js-tab-button-labels')
        expect(page).to have_css('.js-tab-button-assignees')
      end
    end

    it 'shows simple dropdown with only labels list' do
      stub_licensed_features(board_assignee_lists: false)

      visit_board_page

      page.within('#js-add-list') do
        page.find('.js-new-board-list').click
        wait_for_requests
        expect(page).to have_css('.dropdown-menu.js-tab-container-labels')
        expect(page).to have_content('Create lists from labels. Issues with that label appear in that list.')
        expect(page).not_to have_css('.js-tab-button-assignees')
      end
    end
  end

  context 'swimlanes dropdown' do
    context 'feature flag on' do
      before do
        stub_licensed_features(swimlanes: true)
        stub_feature_flags(boards_with_swimlanes: true, swimlanes: true)
      end

      it 'does not show Group by dropdown when user is not logged in' do
        visit_board_page

        expect(page).to have_css('.filtered-search-block')
        expect(page).not_to have_css('.board-swimlanes-toggle-wrapper')
      end

      it 'shows Group by dropdown when user is logged in' do
        login_as(user)
        visit_board_page

        expect(page).to have_css('.board-swimlanes-toggle-wrapper')
      end
    end

    context 'feature flag off' do
      before do
        stub_feature_flags(boards_with_swimlanes: false, swimlanes: false)
      end

      it 'does not show Group by dropdown when user is not logged in' do
        visit_board_page

        expect(page).to have_css('.filtered-search-block')
        expect(page).not_to have_css('.board-swimlanes-toggle-wrapper')
      end

      it 'does not show Group by dropdown when user is logged in' do
        login_as(user)
        visit_board_page

        expect(page).to have_css('.filtered-search-block')
        expect(page).not_to have_css('.board-swimlanes-toggle-wrapper')
      end
    end
  end

  context 'total weight' do
    let!(:label) { create(:label, project: project, name: 'Label 1') }
    let!(:list) { create(:list, board: board, label: label, position: 0) }
    let!(:issue) { create(:issue, project: project, weight: 3) }
    let!(:issue_2) { create(:issue, project: project, weight: 2) }

    before do
      project.add_developer(user)
      login_as(user)
      visit_board_page
    end

    it 'shows total weight for backlog' do
      backlog = board.lists.first
      expect(badge(backlog)).to have_content('5')
    end

    it 'updates weight when moving to list' do
      from = board.lists.first
      to = list

      drag_to(selector: '.board-list',
              scrollable: '#board-app',
              list_from_index: 0,
              from_index: 0,
              to_index: 0,
              list_to_index: 1)

      expect(badge(from)).to have_content('3')
      expect(badge(to)).to have_content('2')
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(issue_weights: false)
        visit_board_page
      end

      it 'hides weight' do
        expect(page).not_to have_text('2 issues')

        backlog = board.lists.first
        badge(backlog).hover

        expect(page).to have_text('2 issues')
      end
    end
  end

  context 'locked milestone' do
    before do
      visit project_board_path(project, board_with_milestone)
      wait_for_requests
    end

    it 'does not have remove button' do
      expect(page).to have_selector('.js-visual-token .remove-token', count: 0)
    end

    it 'is not able to be backspaced' do
      find('.input-token .filtered-search').native.send_key(:backspace)
      expect(page).to have_selector('.js-visual-token', count: 1)
    end
  end

  context 'list header' do
    let(:max_issue_count) { 2 }
    let!(:label) { create(:label, project: project, name: 'Label 2') }
    let!(:list) { create(:list, board: board, label: label, position: 0, max_issue_count: max_issue_count) }
    let!(:issue) { create(:issue, project: project, labels: [label]) }

    before do
      project.add_developer(user)
      login_as(user)
      visit_board_page
    end

    context 'When FF is turned on' do
      context 'when max issue count is set' do
        let(:total_development_issues) { "1" }

        it 'displays issue and max issue size' do
          page.within(find(".board:nth-child(2)")) do
            expect(page.find('.js-issue-size')).to have_text(total_development_issues)
            expect(page.find('.js-max-issue-size')).to have_text(max_issue_count)
          end
        end
      end
    end
  end

  context 'list settings' do
    before do
      project.add_developer(user)
      login_as(user)
    end

    context 'When license is available' do
      let!(:label) { create(:label, project: project, name: 'Brount') }
      let!(:list) { create(:list, board: board, label: label, position: 1) }

      before do
        stub_licensed_features(wip_limits: true)
        visit_board_page
      end

      it 'shows the list settings button' do
        expect(page).to have_selector(:button, "List settings")
        expect(page).not_to have_selector(".js-board-settings-sidebar")
      end

      context 'when settings button is clicked' do
        it 'shows the board list settings sidebar' do
          page.within(find(".board:nth-child(2)")) do
            click_button('List settings')
          end

          expect(page.find('.js-board-settings-sidebar').find('.gl-label-text')).to have_text("Brount")
        end
      end

      context 'when boards setting sidebar is open' do
        before do
          page.within(find(".board:nth-child(2)")) do
            click_button('List settings')
          end
        end

        context "when user clicks Remove Limit" do
          before do
            max_issue_count = 2
            page.within(find('.js-board-settings-sidebar')) do
              click_button("Edit")

              find('input').set(max_issue_count)
            end

            # Off click
            find('body').click

            wait_for_requests
          end

          it "sets max issue count to zero" do
            page.find('.js-remove-limit').click

            wait_for_requests

            expect(page.find('.js-wip-limit')).to have_text("None")
          end
        end

        context 'when the user is editing a wip limit and clicks close' do
          it 'updates the max issue count wip limit' do
            max_issue_count = 3
            page.within(find('.js-board-settings-sidebar')) do
              click_button("Edit")

              find('input').set(max_issue_count)
            end

            # Off click
            # Danger: coupling to gitlab-ui class name for close.
            # Change when https://gitlab.com/gitlab-org/gitlab-ui/issues/578 is resolved
            find('.gl-drawer-close-button').click

            wait_for_requests

            page.within(find(".board:nth-child(2)")) do
              click_button('List settings')
            end

            expect(page.find('.js-wip-limit')).to have_text(max_issue_count)
          end
        end

        context "when user off clicks" do
          it 'updates the max issue count wip limit' do
            max_issue_count = 2
            page.within(find('.js-board-settings-sidebar')) do
              click_button("Edit")

              find('input').set(max_issue_count)
            end

            # Off click
            find('body').click

            wait_for_requests

            expect(page.find('.js-wip-limit')).to have_text(max_issue_count)
          end

          context "When user sets max issue count to 0" do
            it 'updates the max issue count wip limit to None' do
              max_issue_count = 0
              page.within(find('.js-board-settings-sidebar')) do
                click_button("Edit")

                find('input').set(max_issue_count)
              end

              # Off click
              find('body').click

              wait_for_requests

              expect(page.find('.js-wip-limit')).to have_text("None")
            end
          end
        end

        context "when user hits enter" do
          it 'updates the max issue count wip limit' do
            page.within(find('.js-board-settings-sidebar')) do
              click_button("Edit")

              find('input').set(1).native.send_keys(:return)
            end

            wait_for_requests

            expect(page.find('.js-wip-limit')).to have_text(1)
          end
        end
      end
    end

    context 'When license is not available' do
      before do
        stub_licensed_features(wip_limits: false)
        visit project_boards_path(project)
      end

      it 'does not show the list settings button' do
        expect(page).to have_no_selector(:button, "List settings")
        expect(page).not_to have_selector(".js-board-settings-sidebar")
      end
    end
  end

  def badge(list)
    find(".board[data-id='#{list.id}'] .issue-count-badge")
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end
end
