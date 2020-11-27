# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin/push_rules/_merge_request_approvals' do
  let(:application_setting) { build(:application_setting) }

  before do
    assign(:application_setting, application_setting)

    stub_licensed_features(admin_merge_request_approvers_rules: true)
  end

  it 'shows settings form', :aggregate_failures do
    render

    expect(rendered).to have_content('Merge requests approvals')
    expect(rendered).to have_content('Settings to prevent self-approval across all projects')
  end
end
