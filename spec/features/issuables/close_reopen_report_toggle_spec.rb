# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issuables Close/Reopen/Report toggle' do
  include IssuablesHelper

  let(:user) { create(:user) }

  before do
    stub_feature_flags(vue_issue_header: false)
  end

  shared_examples 'an issuable close/reopen/report toggle' do
    let(:container) { find('.issuable-close-dropdown') }
    let(:human_model_name) { issuable.model_name.human.downcase }

    it 'shows toggle' do
      expect(page).to have_button("Close #{human_model_name}")
      expect(page).to have_selector('.issuable-close-dropdown')
    end

    it 'opens a dropdown when toggle is clicked' do
      container.find('.dropdown-toggle').click

      expect(container).to have_selector('.dropdown-menu')
      expect(container).to have_content("Close #{human_model_name}")
      expect(container).to have_content('Report abuse')
      expect(container).to have_content("Report #{human_model_name.pluralize} that are abusive, inappropriate or spam.")

      if issuable.is_a?(MergeRequest)
        page.within('.js-issuable-close-dropdown') do
          expect(page).to have_link('Close merge request')
        end
      else
        expect(container).to have_selector('.close-item.droplab-item-selected')
      end

      expect(container).to have_selector('.report-item')
      expect(container).not_to have_selector('.report-item.droplab-item-selected')
      expect(container).not_to have_selector('.reopen-item')
    end

    it 'links to Report Abuse' do
      container.find('.dropdown-toggle').click
      container.find('.report-abuse-link').click

      expect(page).to have_content('Report abuse to admin')
    end
  end

  context 'on an issue' do
    let(:project) { create(:project) }
    let(:issuable) { create(:issue, project: project) }

    before do
      project.add_maintainer(user)
      login_as user
    end

    context 'when user has permission to update', :js do
      before do
        visit project_issue_path(project, issuable)
      end

      it_behaves_like 'an issuable close/reopen/report toggle'

      context 'when the issue is closed and locked' do
        let(:issuable) { create(:issue, :closed, :locked, project: project) }

        it 'hides the reopen button' do
          expect(page).not_to have_button('Reopen issue')
        end

        context 'when the issue author is the current user' do
          before do
            issuable.update(author: user)
          end

          it 'hides the reopen button' do
            expect(page).not_to have_button('Reopen issue')
          end
        end
      end
    end

    context 'when user doesnt have permission to update' do
      let(:cant_project) { create(:project) }
      let(:cant_issuable) { create(:issue, project: cant_project) }

      before do
        cant_project.add_guest(user)

        visit project_issue_path(cant_project, cant_issuable)
      end

      it 'only shows the `Report abuse` and `New issue` buttons' do
        expect(page).to have_link('Report abuse')
        expect(page).to have_link('New issue')
        expect(page).not_to have_button('Close issue')
        expect(page).not_to have_button('Reopen issue')
        expect(page).not_to have_link(title: 'Edit title and description')
      end
    end
  end

  context 'on a merge request' do
    let(:container) { find('.detail-page-header-actions') }
    let(:project) { create(:project, :repository) }
    let(:issuable) { create(:merge_request, source_project: project) }

    before do
      project.add_maintainer(user)
      login_as user
    end

    context 'when user has permission to update', :js do
      before do
        visit project_merge_request_path(project, issuable)
      end

      it_behaves_like 'an issuable close/reopen/report toggle'

      context 'when the merge request is open' do
        let(:issuable) { create(:merge_request, :opened, source_project: project) }

        it 'shows the `Edit` and `Mark as draft` buttons' do
          expect(container).to have_link('Edit')
          expect(container).to have_link('Mark as draft')
          expect(container).not_to have_button('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).not_to have_link('Reopen merge request')
        end
      end

      context 'when the merge request is closed' do
        let(:issuable) { create(:merge_request, :closed, source_project: project) }

        it 'shows both the `Edit` and `Reopen` button' do
          expect(container).to have_link('Edit')
          expect(container).not_to have_button('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).to have_link('Reopen merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :closed, source_project: project, author: user) }

          it 'shows both the `Edit` and `Reopen` button' do
            expect(container).to have_link('Edit')
            expect(container).not_to have_link('Report abuse')
            expect(container).not_to have_selector('button.dropdown-toggle')
            expect(container).not_to have_button('Close merge request')
            expect(container).to have_link('Reopen merge request')
          end
        end
      end

      context 'when the merge request is merged' do
        let(:issuable) { create(:merge_request, :merged, source_project: project) }

        it 'shows only the `Edit` button' do
          expect(container).to have_link(exact_text: 'Edit')
          expect(container).not_to have_link('Report abuse')
          expect(container).not_to have_button('Close merge request')
          expect(container).not_to have_button('Reopen merge request')
        end

        context 'when the merge request author is the current user' do
          let(:issuable) { create(:merge_request, :merged, source_project: project, author: user) }

          it 'shows only the `Edit` button' do
            expect(container).to have_link(exact_text: 'Edit')
            expect(container).not_to have_link('Report abuse')
            expect(container).not_to have_button('Close merge request')
            expect(container).not_to have_button('Reopen merge request')
          end
        end
      end
    end

    context 'when user doesnt have permission to update' do
      let(:cant_project) { create(:project, :repository) }
      let(:cant_issuable) { create(:merge_request, source_project: cant_project) }

      before do
        cant_project.add_reporter(user)

        visit project_merge_request_path(cant_project, cant_issuable)
      end

      it 'only shows a `Report abuse` button' do
        expect(container).to have_link('Report abuse')
        expect(container).not_to have_button('Close merge request')
        expect(container).not_to have_button('Reopen merge request')
        expect(container).not_to have_link(exact_text: 'Edit')
      end
    end
  end
end
