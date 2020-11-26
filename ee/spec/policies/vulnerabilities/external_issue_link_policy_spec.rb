# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ExternalIssueLinkPolicy do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }
  let(:vulnerability) { create(:vulnerability, project: project) }
  let(:vulnerability_external_issue_link) { build(:vulnerabilities_external_issue_link, vulnerability: vulnerability, author: user) }

  subject { described_class.new(user, vulnerability_external_issue_link) }

  context 'with a user authorized to admin vulnerability-external issue links' do
    before do
      stub_licensed_features(security_dashboard: true)

      project.add_developer(user)
    end

    context 'with missing vulnerability' do
      let(:vulnerability) { nil }

      it { is_expected.to be_disallowed(:admin_vulnerability_external_issue_link) }
    end

    context 'when vulnerability is not missing' do
      it { is_expected.to be_allowed(:admin_vulnerability_external_issue_link) }
    end
  end
end
