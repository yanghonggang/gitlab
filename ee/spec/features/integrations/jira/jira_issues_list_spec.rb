# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira issues list' do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_service, project: project, issues_enabled: true, project_key: 'GL') }
  let(:user) { create(:user) }

  before do
    stub_licensed_features(jira_issues_integration: true)
    stub_feature_flags(jira_issues_list: false)
    project.add_user(user, :developer)
    sign_in(user)
  end

  context 'when jira_issues_integration licensed feature is not available' do
    before do
      stub_licensed_features(jira_issues_integration: false)
    end

    it 'renders "Create new issue" button' do
      visit project_integrations_jira_issues_path(project)

      expect(page).to have_gitlab_http_status(:not_found)
      expect(page).not_to have_link('Create new issue in Jira')
    end
  end

  it 'renders "Create new issue" button' do
    visit project_integrations_jira_issues_path(project)

    expect(page).to have_link('Create new issue in Jira')
  end
end
