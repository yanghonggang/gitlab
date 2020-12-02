# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ComplianceManagement::Frameworks::Destroy do
  include GraphqlHelpers

  let_it_be(:framework) { create(:compliance_framework) }
  let(:user) { framework.namespace.owner }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  subject { mutation.resolve(id: global_id_of(framework)) }

  shared_examples 'no compliance frameworks were destroyed' do
    it 'does not destroy a compliance framework' do
      expect { subject }.not_to change { ComplianceManagement::Framework.count }
    end

    it 'expects at least one error in the response' do
      expect(subject[:errors]).not_to be_empty
    end
  end

  shared_examples 'one compliance framework was destroyed' do
    it 'destroys a compliance framework' do
      expect { subject }.to change { ComplianceManagement::Framework.count }.by(-1)
    end

    it 'expects zero errors in the response' do
      expect(subject[:errors]).to be_empty
    end
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'no compliance frameworks were destroyed'
  end

  context 'feature is disabled but is licensed' do
    before do
      stub_feature_flags(ff_custom_compliance_frameworks: false)
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    it_behaves_like 'no compliance frameworks were destroyed'
  end

  context 'feature is enabled and licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
      stub_feature_flags(ff_custom_compliance_frameworks: true)
    end

    context 'current_user is namespace owner' do
      it_behaves_like 'one compliance framework was destroyed'
    end

    context 'current_user is group owner' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_framework) { create(:compliance_framework, namespace: group)}

      before do
        group.add_owner(user)
      end

      it_behaves_like 'one compliance framework was destroyed'
    end
  end
end
