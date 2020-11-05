# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list) { create(:list, board: board, label: label, position: 0) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label]) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:issue3) { create(:issue, project: project) }

  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }

  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, issue: issue2) }

  context 'link to swimlanes view' do
    before do
      stub_licensed_features(epics: true)
      sign_in(user)
      visit_epics_swimlanes_page
    end

    it 'displays epics swimlanes when link to boards with group_by epic in URL' do
      expect(page).to have_selector('[data-testid="board-swimlanes"]')

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)
    end

    it 'displays issue not assigned to epic in unassigned issues lane' do
      page.within('.board-lane-unassigned-issues-title') do
        expect(page.find('span[data-testid="issues-lane-issue-count"]')).to have_content('1')
      end
    end
  end

  before do
    stub_licensed_features(epics: true, swimlanes: true)
    sign_in(user)
    visit_board_page
    select_epics
  end

  context 'switch to swimlanes view' do
    it 'displays epics swimlanes when selecting Epic in Group by dropdown' do
      expect(page).to have_selector('[data-testid="board-swimlanes"]')

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)
    end

    it 'displays issue not assigned to epic in unassigned issues lane' do
      page.within('.board-lane-unassigned-issues-title') do
        expect(page.find('span[data-testid="issues-lane-issue-count"]')).to have_content('1')
      end
    end
  end

  context 'add issue to swimlanes list' do
    it 'displays new issue button' do
      expect(first('.board')).to have_selector('.issue-count-badge-add-button', count: 1)
    end

    it 'shows form in unassigned issues lane when clicking button' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within("[data-testid='board-lane-unassigned-issues']") do
        expect(page).to have_selector('.board-new-issue-form')
      end
    end

    it 'hides form when clicking cancel' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within("[data-testid='board-lane-unassigned-issues']") do
        expect(page).to have_selector('.board-new-issue-form')

        click_button 'Cancel'

        expect(page).not_to have_selector('.board-new-issue-form')
      end
    end

    it 'creates new issue in unassigned issues lane' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      wait_for_all_requests

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('bug')
        click_button 'Submit issue'
      end

      wait_for_all_requests

      page.within(first('.board .issue-count-badge-count')) do
        expect(page).to have_content('3')
      end

      page.within("[data-testid='board-lane-unassigned-issues']") do
        page.within(first('.board-card')) do
          issue = project.issues.find_by!(title: 'bug')

          expect(page).to have_content(issue.to_reference)
        end
      end
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end

  def select_epics
    page.within('.board-swimlanes-toggle-wrapper') do
      page.find('.dropdown-toggle').click
      page.find('.dropdown-item', text: 'Epic').click
    end
  end

  def visit_epics_swimlanes_page
    visit "#{project_boards_path(project)}?group_by=epic"
    wait_for_requests
  end
end
