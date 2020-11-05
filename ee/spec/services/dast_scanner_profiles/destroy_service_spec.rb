# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastScannerProfiles::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:dast_scanner_profile, reload: true) { create(:dast_scanner_profile, target_timeout: 200, spider_timeout: 5000) }
  let(:project) { dast_scanner_profile.project }

  before do
    stub_licensed_features(security_on_demand_scans: true)
  end

  describe '#execute' do
    subject do
      described_class.new(project, user).execute(
        id: dast_scanner_profile_id
      )
    end

    let(:dast_scanner_profile_id) { dast_scanner_profile.id }
    let(:status) { subject.status }
    let(:message) { subject.message }
    let(:payload) { subject.payload }

    context 'when a user does not have access to the project' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('You are not authorized to update this scanner profile')
      end
    end

    context 'when the user can run a DAST scan' do
      before do
        project.add_developer(user)
      end

      it 'returns a success status' do
        expect(status).to eq(:success)
      end

      it 'deletes the dast_scanner_profile' do
        expect { subject }.to change { DastScannerProfile.count }.by(-1)
      end

      it 'returns a dast_scanner_profile payload' do
        expect(payload).to be_a(DastScannerProfile)
      end

      context 'when the dast_scanner_profile doesn\'t exist' do
        let(:dast_scanner_profile_id) do
          Gitlab::GlobalId.build(nil, model_name: 'DastScannerProfile', id: 'does_not_exist')
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('Scanner profile not found for given parameters')
        end
      end

      context 'when on demand scan licensed feature is not available' do
        before do
          stub_licensed_features(security_on_demand_scans: false)
        end

        it 'returns an error status' do
          expect(status).to eq(:error)
        end

        it 'populates message' do
          expect(message).to eq('You are not authorized to update this scanner profile')
        end
      end
    end
  end
end
