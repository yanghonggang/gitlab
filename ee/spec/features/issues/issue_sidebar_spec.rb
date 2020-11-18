# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Sidebar' do
  include MobileHelpers

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:project_without_group) { create(:project, :public) }
  let_it_be(:user) { create(:user)}
  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:issue) { create(:labeled_issue, project: project, labels: [label]) }
  let_it_be(:issue_no_group) { create(:labeled_issue, project: project_without_group, labels: [label]) }

  before do
    stub_feature_flags(vue_issue_header: false)

    sign_in(user)
  end

  context 'updating weight', :js do
    before do
      project.add_maintainer(user)
      visit_issue(project, issue)
    end

    it 'updates weight in sidebar to 1' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end
      end
    end

    it 'updates weight in sidebar to no weight' do
      page.within '.weight' do
        click_link 'Edit'
        find('input').send_keys 1, :enter

        page.within '.value' do
          expect(page).to have_content '1'
        end

        click_link 'remove weight'

        page.within '.value' do
          expect(page).to have_content 'None'
        end
      end
    end
  end

  context 'as a guest' do
    before do
      project.add_guest(user)
      visit_issue(project, issue)
    end

    it 'does not have a option to edit weight' do
      expect(page).not_to have_selector('.block.weight .js-weight-edit-link')
    end
  end

  context 'as a guest, interacting with collapsed sidebar', :js do
    before do
      project.add_guest(user)
      resize_screen_sm
      visit_issue(project, issue)
    end

    it 'edit weight field does not appear after clicking on weight when sidebar is collapsed then expanding it' do
      find('.js-weight-collapsed-block').click
      # Expand sidebar
      open_issue_sidebar
      expect(page).not_to have_selector('.block.weight .form-control')
    end
  end

  context 'health status', :js do
    before do
      project.add_developer(user)
    end

    context 'when health status feature is available' do
      before do
        stub_licensed_features(issuable_health_status: true)

        visit_issue(project, issue)
      end

      it 'shows health status on sidebar' do
        expect(page).to have_selector('.block.health-status')
      end

      context 'when user closes an issue' do
        it 'disables the edit button' do
          page.find('[data-testid="close-issue-button"]').click

          page.within('.health-status') do
            expect(page).to have_button('Edit', disabled: true)
          end
        end
      end
    end

    context 'when health status feature is not available' do
      it 'does not show health status on sidebar' do
        stub_licensed_features(issuable_health_status: false)

        visit_issue(project, issue)

        expect(page).not_to have_selector('.block.health-status')
      end
    end

    context 'when health status feature flag is disabled' do
      it 'does not show health status on sidebar' do
        stub_licensed_features(issuable_health_status: true)
        stub_feature_flags(save_issuable_health_status: false)

        visit_issue(project, issue)

        expect(page).not_to have_selector('.block.health-status')
      end
    end
  end

  context 'Iterations', :js do
    context 'when iterations feature available' do
      let_it_be(:iteration) { create(:iteration, group: group, start_date: 1.day.from_now, due_date: 2.days.from_now, title: 'Iteration 1') }
      let_it_be(:iteration2) { create(:iteration, group: group, start_date: 2.days.ago, due_date: 1.day.ago, title: 'Iteration 2', state: 'closed', skip_future_date_validation: true) }

      before do
        iteration
        stub_licensed_features(iterations: true)

        project.add_developer(user)

        visit_issue(project, issue)

        wait_for_all_requests
      end

      it 'selects and updates the right iteration' do
        find_and_click_edit_iteration

        select_iteration(iteration.title)

        expect(page.find('[data-testid="select-iteration"]')).to have_content('Iteration 1')

        find_and_click_edit_iteration

        select_iteration('No iteration')

        expect(page.find('[data-testid="select-iteration"]')).to have_content('No iteration')
      end

      it 'does not show closed iterations' do
        find_and_click_edit_iteration

        page.within '.milestone' do
          expect(page).not_to have_content iteration2.title
        end
      end
    end

    context 'when a project does not have a group' do
      before do
        stub_licensed_features(iterations: true)

        project_without_group.add_developer(user)

        visit_issue(project_without_group, issue_no_group)

        wait_for_all_requests
      end

      it 'cannot find the select-iteration edit button' do
        expect(page).not_to have_selector('[data-testid="select-iteration"]')
      end
    end

    context 'when iteration feature is not available' do
      before do
        stub_licensed_features(iterations: false)

        project.add_developer(user)

        visit_issue(project, issue)

        wait_for_all_requests
      end

      it 'cannot find the select-iteration edit button' do
        expect(page).not_to have_selector('[data-testid="select-iteration"]')
      end
    end
  end

  def find_and_click_edit_iteration
    page.find('[data-testid="iteration-edit-link"]').click
  end

  def select_iteration(iteration_name)
    click_button(iteration_name)

    wait_for_all_requests
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end

  def open_issue_sidebar
    find('aside.right-sidebar.right-sidebar-collapsed .js-sidebar-toggle').click
    find('aside.right-sidebar.right-sidebar-expanded')
  end
end
