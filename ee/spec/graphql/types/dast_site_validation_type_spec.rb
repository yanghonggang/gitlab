# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['DastSiteValidation'] do
  let_it_be(:dast_site_validation) { create(:dast_site_validation) }
  let_it_be(:project) { dast_site_validation.dast_site_token.project }
  let_it_be(:user) { create(:user) }
  let_it_be(:fields) { %i[id status] }

  let(:response) do
    GitlabSchema.execute(
      query,
      context: {
        current_user: user
      },
      variables: {
        fullPath: project.full_path,
        targetUrl: dast_site_validation.url_base
      }
    ).as_json
  end

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class.graphql_name).to eq('DastSiteValidation') }
  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe 'dast_site_validation' do
    before do
      project.add_developer(user)
    end

    let(:query) do
      %(
        query project($fullPath: ID!, $targetUrl: String!) {
          project(fullPath: $fullPath) {
            dastSiteValidation(targetUrl: $targetUrl) {
              id
              status
            }
          }
        }
      )
    end

    describe 'status field' do
      subject { response.dig('data', 'project', 'dastSiteValidation', 'status') }

      it { is_expected.to eq('PENDING_VALIDATION') }
    end
  end
end
