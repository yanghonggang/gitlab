# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Wrapper do
  let(:config_file_name) { "config/resque.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_CONFIG_FILE" }
  let(:config_old_format_socket) { "spec/fixtures/config/redis_old_format_socket.yml" }
  let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }
  let(:old_socket_path) {"/path/to/old/redis.sock" }
  let(:new_socket_path) {"/path/to/redis.sock" }
  let(:config_old_format_host) { "spec/fixtures/config/redis_old_format_host.yml" }
  let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
  let(:redis_port) { 6379 }
  let(:redis_database) { 99 }
  let(:sentinel_port) { redis_port + 20000 }
  let(:config_with_environment_variable_inside) { "spec/fixtures/config/redis_config_with_env.yml"}
  let(:config_env_variable_url) {"TEST_GITLAB_REDIS_URL"}
  let(:class_redis_url) { Gitlab::Redis::Wrapper::DEFAULT_REDIS_URL }

  include_examples "redis_shared_examples" do
    before do
      allow(described_class).to receive(:instrumentation_class) do
        ::Gitlab::Instrumentation::Redis::Cache
      end
    end
  end

  describe '.version' do
    it 'returns a version' do
      expect(described_class.version).to be_present
    end
  end

  describe '.instrumentation_class' do
    it 'raises a NotImplementedError' do
      expect(described_class).to receive(:instrumentation_class).and_call_original

      expect { described_class.instrumentation_class }.to raise_error(NotImplementedError)
    end
  end

  describe '.config_file_path' do
    it 'returns the absolute path to the configuration file' do
      expect(described_class.config_file_path('foo.yml'))
        .to eq Rails.root.join('config', 'foo.yml').to_s
    end
  end
end
