# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20201116142400_add_new_data_to_issues_documents.rb')

RSpec.describe AddNewDataToIssuesDocuments, :elastic, :sidekiq_inline do
  let(:version) { 20201116142400 }
  let(:migration) { described_class.new(version) }
  let(:issues) { create_list(:issue, 3) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    # ensure issues are indexed
    issues

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
        add_visibility_level_for_issues(issues)
      end

      it 'does not modify data', :aggregate_failures do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:track!)

        expect(subject).to be_falsey
      end
    end

    context 'migration process' do
      before do
        remove_visibility_level_for_issues(issues)
      end

      it 'updates all issue documents' do
        expect(::Elastic::ProcessBookkeepingService).to receive(:track!).exactly(3).times

        expect(subject).to be_truthy
      end
    end
  end

  describe '.completed?' do
    subject { migration.completed? }

    context 'when documents are missing visibility_level' do
      before do
        remove_visibility_level_for_issues(issues)
      end

      it { is_expected.to be_falsey }
    end

    context 'when no documents are missing visibility_level' do
      before do
        add_visibility_level_for_issues(issues)
      end

      it { is_expected.to be_truthy }
    end
  end

  private

  def add_visibility_level_for_issues(issues)
    script =  {
      source: "ctx._source['visibility_level'] = params.visibility_level;",
      lang: "painless",
      params: {
        visibility_level: Gitlab::VisibilityLevel::PRIVATE
      }
    }

    update_by_query(issues, script)
  end

  def remove_visibility_level_for_issues(issues)
    script =  {
      source: "ctx._source.remove('visibility_level')"
    }

    update_by_query(issues, script)
  end

  def update_by_query(issues, script)
    issue_ids = issues.map { |i| i.id }

    client = Issue.__elasticsearch__.client
    client.update_by_query({
      index: Issue.__elasticsearch__.index_name,
      wait_for_completion: true, # run synchronously
      refresh: true, # make operation visible to search
      body: {
        script: script,
        query: {
          bool: {
            must: [
              {
                terms: {
                  id: issue_ids
                }
              },
              {
                term: {
                  type: {
                    value: 'issue'
                  }
                }
              }
            ]
          }
        }
      }
    })
  end
end
