# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastSiteProfiles::Delete do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }
  let(:full_path) { project.full_path }
  let!(:dast_site_profile) { create(:dast_site_profile, project: project) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        id: dast_site_profile.to_global_id
      )
    end

    context 'when on demand scan feature is enabled' do
      context 'when the project does not exist' do
        let(:full_path) { SecureRandom.hex }

        it 'raises an exception' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end

      context 'when the user can run a dast scan' do
        before do
          project.add_developer(user)
        end

        it 'deletes the dast_site_profile' do
          expect { subject }.to change { DastSiteProfile.count }.by(-1)
        end

        context 'when there is an issue deleting the dast_site_profile' do
          it 'returns an error' do
            allow(mutation).to receive(:find_dast_site_profile).and_return(dast_site_profile)
            allow(dast_site_profile).to receive(:destroy).and_return(false)
            dast_site_profile.errors.add(:name, 'is weird')

            expect(subject[:errors]).to include('Name is weird')
          end
        end
      end
    end
  end
end
