# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User manages merge trains option', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    stub_licensed_features(merge_pipelines: true, merge_trains: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  it 'sees unchecked merge trains checkbox' do
    visit edit_project_path(project)

    expect(page.find('#project_merge_trains_enabled')).not_to be_checked
  end

  context 'when user enabled the checkbox' do
    before do
      visit edit_project_path(project)

      check('Enable merge trains.')
    end

    it 'sees enabled merge trains checkbox' do
      expect(page.find('#project_merge_trains_enabled')).to be_checked
    end
  end

  context 'when license is insufficient' do
    before do
      stub_licensed_features(merge_pipelines: false, merge_trains: false)
    end

    it 'does not see the checkbox' do
      expect(page).not_to have_css('#project_merge_trains_enabled')
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(merge_pipelines: false, merge_trains: false)
    end

    it 'does not see the checkbox' do
      expect(page).not_to have_css('#project_merge_trains_enabled')
    end
  end
end
