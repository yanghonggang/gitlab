# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20201116142400_add_new_data_to_issues_documents.rb')

RSpec.describe AddNewDataToIssuesDocuments, :elastic, :sidekiq_inline do
  let(:logger) { double('Gitlab::Elasticsearch::Logger') }
  let(:version) { 20201116142400 }
  let(:migration) { described_class.new(version) }
  let(:issues) { create_list(:issue, 3) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(described_class.get_migration_options[:batched]).to be_truthy
      expect(described_class.get_migration_options[:throttle_delay]).to eq(5.minutes)
    end
  end

  describe '.migrate' do
    subject { migration.migrate }

    context 'when migration is already completed' do
      before do
        allow(migration).to receive(:completed?).and_return(true)
      end

      it 'logs a message and does not modify data', :aggregate_failures do
        allow(::Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger)

        expect(logger).to receive(:info).once
        expect(::Gitlab::Elastic::Helper.default.client).not_to receive(:search)

        expect(subject).to be_falsey
      end
    end

    context 'migration process' do
      before do
        allow(migration).to receive(:completed?).and_return(false)

        remove_visibility_level_from_index
      end

      it 'updates all issue documents and logs a message', :aggregate_failures do
        allow(::Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger)

        expect(::Gitlab::Elastic::Helper.default.client).to receive(:search).and_call_original
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).exactly(3).times
        expect(logger).to receive(:info).twice

        expect(subject).to be_truthy
      end
    end
  end

  describe '.completed?' do
    using RSpec::Parameterized::TableSyntax

    subject { migration.completed? }

    where(:doc_count, :expected) do
      0 | true
      5 | false
    end

    with_them do
      it 'returns whether documents missing data are found' do
        remove_visibility_level_from_index unless expected

        expect(subject).to eq(expected)
      end
    end
  end

  private

  def remove_visibility_level_from_index
    # the issue_instance_proxy has been updated to send `visibility_level` so it
    # needs to be overridden to test this migration
    issues.each do |issue|
      proxy = ::Elastic::Latest::IssueInstanceProxy.new(issue)
      issue_json_modified = issue.__elasticsearch__.as_indexed_json.except('visibility_level')
      allow(proxy).to receive(:as_indexed_json).and_return(issue_json_modified)
      allow(::Elastic::Latest::IssueInstanceProxy).to receive(:new).and_return(proxy)
    end

    ensure_elasticsearch_index!
  end
end
