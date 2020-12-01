# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ComplianceManagement::Frameworks::Create do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let(:params) { valid_params }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }

  subject { mutation.resolve(params) }

  describe '#resolve' do
    context 'feature is unlicensed' do
      before do
        stub_licensed_features(custom_compliance_frameworks: false)
      end

      it 'does not create a new compliance framework' do
        expect { subject }.not_to change { namespace.compliance_management_frameworks.count }
      end

      it 'returns useful error messages' do
        expect(subject[:errors]).to include('Not permitted to create framework')
      end
    end

    context 'feature is licensed' do
      before do
        stub_licensed_features(custom_compliance_frameworks: true)
      end

      context 'feature is disabled' do
        let_it_be(:namespace) { create(:group) }

        before do
          stub_feature_flags(ff_custom_compliance_frameworks: false)
          namespace.add_owner(current_user)
        end

        it 'does not create a new compliance framework' do
          expect { subject }.not_to change { namespace.compliance_management_frameworks.count }
        end

        it 'returns useful error messages' do
          expect(subject[:errors]).to include 'Not permitted to create framework'
        end
      end

      context 'current_user is not namespace owner' do
        let_it_be(:namespace) { create(:namespace, owner: build(:user)) }

        it 'does not create a new compliance framework' do
          expect { subject }.not_to change { namespace.compliance_management_frameworks.count }
        end

        it 'returns useful error messages' do
          expect(subject[:errors]).to include 'Not permitted to create framework'
        end
      end

      context 'current_user is group owner' do
        let_it_be(:namespace) { create(:group) }

        before do
          namespace.add_owner(current_user)
        end

        it 'creates a new compliance framework' do
          expect { subject }.to change { namespace.compliance_management_frameworks.count }.by 1
        end
      end

      context 'current_user is namespace owner' do
        let_it_be(:namespace) { create(:namespace, owner: current_user) }

        context 'framework parameters are valid' do
          it 'creates a new compliance framework' do
            expect { subject }.to change { namespace.compliance_management_frameworks.count }.by 1
          end
        end

        context 'framework parameters are invalid' do
          let(:params) { valid_params.merge(color: 'notacolor') }

          it 'does not create a new compliance framework' do
            expect { subject }.not_to change { namespace.compliance_management_frameworks.count }
          end

          it 'returns useful error messages' do
            puts subject
            expect(subject[:errors]).to include 'Color must be a valid color code'
          end
        end
      end
    end
  end

  private

  def valid_params
    {
      namespace_path: namespace.full_path,
      name: 'GDPR',
      description: 'Example description',
      color: '#abc123'
    }
  end
end
