# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscriptions Content Security Policy' do
  subject { response_headers['Content-Security-Policy'] }

  let_it_be(:default_csp_values) { "'self' https://some-cdn.test" }
  let_it_be(:zuora_url) { 'https://*.zuora.com' }

  before do
    stub_request(:get, /.*gitlab_plans.*/).to_return(status: 200, body: "{}")

    expect_next_instance_of(SubscriptionsController) do |controller|
      expect(controller).to receive(:current_content_security_policy).and_return(csp)
    end

    sign_in(create(:user))

    visit new_subscriptions_path
  end

  context 'when there is no global CSP config' do
    let(:csp) { ActionDispatch::ContentSecurityPolicy.new }

    it { is_expected.to be_blank }
  end

  context 'when a global CSP config exists' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.script_src(*default_csp_values.split)
        p.frame_src(*default_csp_values.split)
        p.child_src(*default_csp_values.split)
      end
    end

    it { is_expected.to include("script-src #{default_csp_values} 'unsafe-eval' #{zuora_url}") }
    it { is_expected.to include("frame-src #{default_csp_values} #{zuora_url}") }
    it { is_expected.to include("child-src #{default_csp_values} #{zuora_url}") }
  end

  context 'when just a default CSP config exists' do
    let(:csp) do
      ActionDispatch::ContentSecurityPolicy.new do |p|
        p.default_src(*default_csp_values.split)
      end
    end

    it { is_expected.to include("default-src #{default_csp_values}") }
    it { is_expected.to include("script-src #{default_csp_values} 'unsafe-eval' #{zuora_url}") }
    it { is_expected.to include("frame-src #{default_csp_values} #{zuora_url}") }
    it { is_expected.to include("child-src #{default_csp_values} #{zuora_url}") }
  end
end
