# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::DastScannerProfiles::Delete do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:full_path) { project.full_path }
  let_it_be(:dast_scanner_profile) { create(:dast_scanner_profile, project: project) }
  let(:dast_scanner_profile_id) { dast_scanner_profile.to_global_id }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  specify { expect(described_class).to require_graphql_authorizations(:create_on_demand_dast_scan) }

  describe '#resolve' do
    subject do
      mutation.resolve(
        full_path: full_path,
        id: dast_scanner_profile_id
      )
    end

    context 'when the project does not exist' do
      let(:full_path) { SecureRandom.hex }

      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user is not associated with the project' do
      it 'raises an exception' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when the user can run a DAST scan' do
      before do
        project.add_developer(user)
      end

      it 'deletes the DAST scanner profile' do
        expect { subject }.to change { DastScannerProfile.count }.by(-1)
      end

      context 'when the dast_scanner_profile does not exist' do
        let(:dast_scanner_profile_id) { Gitlab::GlobalId.build(nil, model_name: 'DastScannerProfile', id: 'does_not_exist') }

        it 'returns an error' do
          expect(subject[:errors]).to include('Scanner profile not found for given parameters')
        end
      end

      context 'when deletion fails' do
        it 'returns an error' do
          allow_next_instance_of(::DastScannerProfiles::DestroyService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: 'Scanner profile failed to delete')
            )
          end

          expect(subject[:errors]).to include('Scanner profile failed to delete')
        end
      end
    end
  end
end
