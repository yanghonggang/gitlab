# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'viewing an issue', :js do
  let(:support_bot) { User.support_bot }
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let!(:note) { create(:note_on_issue, project: project, noteable: issue) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  context 'without `issue_email_participants`' do
    before do
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    it 'does not show warning on new note form' do
      expect(find('.new-note')).not_to have_content('will be notified of your comment')
    end

    it 'does not show warning on reply form' do
      find('.js-reply-button').click

      expect(find('.note-edit-form')).not_to have_content('will be notified of your comment')
    end
  end

  context 'with `issue_email_participants`' do
    before do
      issue.issue_email_participants.create!(email: 'a@gitlab.com')
      visit project_issue_path(project, issue)
      wait_for_all_requests
    end

    it 'shows warning on new note form' do
      expect(find('.new-note')).to have_content('a@gitlab.com will be notified of your comment')
    end

    it 'shows warning on reply form' do
      find('.js-reply-button').click
      expect(find('.note-edit-form')).to have_content('a@gitlab.com will be notified of your comment')
    end
  end
end
