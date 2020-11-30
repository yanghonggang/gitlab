# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::AutoFixWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline.id) }

    let_it_be(:pipeline) { create(:ci_pipeline, ref: 'master') }
    let(:project) { pipeline.project }

    context 'when auto_fix feature is enabled' do
      it 'run AutoFix Service' do
        expect_any_instance_of(Security::AutoFixService).to receive(:execute)

        perform
      end
    end

    context 'when auto_fix feature is disabled' do
      before do
        create(:project_security_setting, :disabled_auto_fix, project: project)
      end

      it 'does not run AutoFix Service' do
        expect_any_instance_of(Security::AutoFixService).not_to receive(:execute)

        perform
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(security_auto_fix: false )
      end

      it 'does not run AutoFix Service' do
        expect_any_instance_of(Security::AutoFixService).not_to receive(:execute)

        perform
      end
    end
  end
end
