# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Terraform', :js do
  let_it_be(:project) { create(:project) }

  let(:user) { project.creator }

  before do
    gitlab_sign_in(user)
  end

  context 'when user does not have any terraform states and visits the index page' do
    before do
      visit project_terraform_index_path(project)
    end

    it 'sees an empty state' do
      expect(page).to have_content('Get started with Terraform')
    end
  end

  context 'when user has a terraform state' do
    let_it_be(:terraform_state) { create(:terraform_state, :locked, project: project) }

    context 'when user visits the index page' do
      before do
        visit project_terraform_index_path(project)
      end

      it 'displays a tab with states count' do
        expect(page).to have_content("States #{project.terraform_states.size}")
      end

      it 'displays a table with terraform states' do
        expect(page).to have_selector(
          '[data-testid="terraform-states-table-name"]',
          count: project.terraform_states.size
        )
      end

      it 'displays terraform information' do
        expect(page).to have_content(terraform_state.name)
      end

      it 'displays terraform actions dropdown' do
        expect(page).to have_selector(
          '[data-testid*="terraform-state-actions"]',
          count: project.terraform_states.size
        )
      end
    end

    context 'when deleting a state on the index page' do
      let(:state_2) { create(:terraform_state, project: project) }

      before do
        visit project_terraform_index_path(project)
      end

      it 'deletes terraform state', :aggregate_failures do
        expect(page).to have_content(state_2.name)

        find("[data-testid='terraform-state-actions-#{state_2.name}']").click
        find('[data-testid="terraform-state-remove-action"]').click

        expect(page).not_to have_content(state_2.name)
        expect { state_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when user is not a terraform admin' do
      let_it_be(:developer) { create(:user) }

      before do
        project.add_developer(developer)
        gitlab_sign_in(developer)
        visit project_terraform_index_path(project)
      end

      it 'displays a table without an action dropdown', :aggregate_failures do
        expect(page).to have_selector(
          '[data-testid="terraform-states-table-name"]',
          count: project.terraform_states.size
        )

        expect(page).not_to have_selector('[data-testid*="terraform-state-actions"]')
      end
    end
  end
end
