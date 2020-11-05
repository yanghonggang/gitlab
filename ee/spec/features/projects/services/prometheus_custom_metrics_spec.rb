# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Prometheus custom metrics', :js do
  include PrometheusHelpers

  include_context 'project service activation'

  let!(:prometheus_metric) { create(:prometheus_metric, project: project) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    stub_request(:get, prometheus_query_with_time_url('avg(metric)', Time.now.utc))
    create(:prometheus_service, project: project, api_url: 'http://prometheus.example.com', manual_configuration: '1', active: true)

    visit_project_integration('Prometheus')
  end

  it 'deletes a custom metric' do
    first('.custom-metric-link-bold').click

    click_button('Delete')
    click_button('Delete metric')

    expect(all('.custom-metric-link-bold').count).to eq(0)
  end
end
