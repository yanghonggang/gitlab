# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration' do
  let_it_be(:now) { Time.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, :private, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:sub_project) { create(:project, group: sub_group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:guest_user) { create(:group_member, :guest, user: create(:user), group: group).user }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, iid: 1, id: 2, group: group, title: 'Correct Iteration', description: 'iteration description', start_date: now - 1.day, due_date: now) }
  let_it_be(:other_iteration) { create(:iteration, :skip_future_date_validation, iid: 2, id: 1, group: group, title: 'Wrong Iteration', start_date: now - 4.days, due_date: now - 3.days) }
  let_it_be(:sub_group_iteration) { create(:iteration, id: 3, group: sub_group) }
  let_it_be(:issue) { create(:issue, project: project, iteration: iteration) }
  let_it_be(:assigned_issue) { create(:issue, project: project, iteration: iteration, assignees: [user]) }
  let_it_be(:closed_issue) { create(:closed_issue, project: project, iteration: iteration) }
  let_it_be(:sub_group_issue) { create(:issue, project: sub_project, iteration: iteration) }
  let_it_be(:other_issue) { create(:issue, project: project, iteration: other_iteration) }

  context 'with license', :js do
    before do
      stub_licensed_features(iterations: true)
    end

    shared_examples 'shows iteration info' do
      before do
        sign_in(current_user)

        visit group_iteration_path(iteration.group, iteration.iid)
      end

      it 'shows iteration info' do
        aggregate_failures 'expect title, description, and dates' do
          expect(page).to have_content(iteration.title)
          expect(page).to have_content(iteration.description)
          expect(page).to have_content(iteration.start_date.strftime('%b %-d, %Y'))
          expect(page).to have_content(iteration.due_date.strftime('%b %-d, %Y'))
        end

        aggregate_failures 'expect summary information' do
          expect(page).to have_content("Complete 25%")
          expect(page).to have_content("Open 2")
          expect(page).to have_content("In progress 1")
          expect(page).to have_content("Completed 1")
        end

        aggregate_failures 'expect burnup and burndown charts' do
          expect(page).to have_content('Burndown chart')
          expect(page).to have_content('Burnup chart')
        end

        aggregate_failures 'expect list of assigned issues' do
          expect(page).to have_content(issue.title)
          expect(page).to have_content(assigned_issue.title)
          expect(page).to have_content(closed_issue.title)
          expect(page).to have_content(sub_group_issue.title)
          expect(page).not_to have_content(other_issue.title)
        end

        if shows_actions
          expect(page).to have_button('Actions')
        else
          expect(page).not_to have_button('Actions')
        end
      end
    end

    context 'when user has edit permissions' do
      it_behaves_like 'shows iteration info' do
        let(:current_user) { user }
        let(:shows_actions) { true }
      end
    end

    context 'when user does not have edit permissions' do
      it_behaves_like 'shows iteration info' do
        let(:current_user) { guest_user }
        let(:shows_actions) { false }
      end
    end
  end

  context 'without license' do
    before do
      stub_licensed_features(iterations: false)
      sign_in(user)
    end

    it 'shows page not found' do
      visit group_iteration_path(iteration.group, iteration.iid)

      expect(page).to have_title('Not Found')
      expect(page).to have_content('Page Not Found')
    end
  end
end
