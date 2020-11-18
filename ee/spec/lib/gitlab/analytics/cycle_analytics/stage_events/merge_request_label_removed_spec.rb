# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestLabelRemoved do
  it_behaves_like 'value stream analytics event' do
    let(:params) { { label: GroupLabel.new } }
  end
end
