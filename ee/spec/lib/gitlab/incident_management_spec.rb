# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IncidentManagement do
  let_it_be_with_refind(:project) { create(:project) }

  describe '.oncall_schedules_available?' do
    subject { described_class.oncall_schedules_available?(project) }

    before do
      stub_licensed_features(oncall_schedules: true)
      stub_feature_flags(oncall_schedules_mvc: project)
    end

    it { is_expected.to be_truthy }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(oncall_schedules_mvc: false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when there is no license' do
      before do
        stub_licensed_features(oncall_schedules: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
