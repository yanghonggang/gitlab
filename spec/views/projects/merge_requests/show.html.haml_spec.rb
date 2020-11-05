# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/show.html.haml' do
  before do
    allow(view).to receive(:experiment_enabled?).and_return(false)
  end

  include_context 'merge request show action'

  describe 'merge request assignee sidebar' do
    context 'when assignee is allowed to merge' do
      it 'does not show a warning icon' do
        closed_merge_request.update!(assignee_id: user.id)
        project.add_maintainer(user)
        assign(:issuable_sidebar, serialize_issuable_sidebar(user, project, closed_merge_request))

        render

        expect(rendered).not_to have_css('.merge-icon')
      end
    end
  end

  context 'when the merge request is closed' do
    it 'shows the "Reopen" button' do
      render

      expect(rendered).to have_css('a', visible: true, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end

    it 'does not show the "Reopen" button when the source project does not exist' do
      unlink_project.execute
      closed_merge_request.reload
      preload_view_requirements

      render

      expect(rendered).to have_css('a', visible: false, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end
  end
end
