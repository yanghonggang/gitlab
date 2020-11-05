# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AppendBuildTraceService do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:build) { create(:ci_build, :running, pipeline: pipeline) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  context 'build trace append is successful' do
    it 'returns a correct stream size and status code' do
      stream_size = 192.kilobytes
      body_data = 'x' * stream_size
      content_range = "0-#{stream_size}"

      result = described_class
        .new(build, content_range: content_range)
        .execute(body_data)

      expect(result.status).to eq 202
      expect(result.stream_size).to eq stream_size
      expect(build.trace_chunks.count).to eq 2
    end
  end

  context 'when could not correctly append to a trace' do
    it 'responds with content range violation and data stored' do
      allow(build).to receive_message_chain(:trace, :append) { 16 }

      result = described_class
        .new(build, content_range: '0-128')
        .execute('x' * 128)

      expect(result.status).to eq 416
      expect(result.stream_size).to eq 16
    end

    it 'logs exception if build has live trace' do
      build.trace.append('abcd', 0)

      expect(::Gitlab::ErrorTracking)
        .to receive(:log_exception)
        .with(anything, hash_including(chunk_index: 0, chunk_store: 'redis'))

      result = described_class
        .new(build, content_range: '0-128')
        .execute('x' * 128)

      expect(result.status).to eq 416
      expect(result.stream_size).to eq 4
    end
  end
end
