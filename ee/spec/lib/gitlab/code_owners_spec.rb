# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CodeOwners do
  include FakeBlobHelpers

  let!(:code_owner) { create(:user, username: 'owner-1') }
  let(:project) { create(:project, :repository) }
  let(:codeowner_content) { 'docs/CODEOWNERS @owner-1' }
  let(:codeowner_blob) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }
  let(:codeowner_blob_ref) { fake_blob(path: 'CODEOWNERS', data: codeowner_content) }

  before do
    project.add_developer(code_owner)
    allow(project.repository).to receive(:code_owners_blob)
      .with(ref: codeowner_lookup_ref)
      .and_return(codeowner_blob)
  end

  describe '.for_blob' do
    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:blob) { project.repository.blob_at(branch, 'docs/CODEOWNERS') }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns users for a blob' do
        expect(described_class.for_blob(project, blob)).to include(code_owner)
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns no users' do
        expect(described_class.for_blob(project, blob)).to be_empty
      end
    end
  end

  describe '.sections_for_ref' do
    subject { described_class.sections_for_ref(project, branch) }

    let(:branch) { TestEnv::BRANCH_SHA['with-codeowners'] }
    let(:codeowner_lookup_ref) { branch }

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns sections' do
        is_expected.to match_array(['codeowners'])
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe ".fast_path_lookup and .slow_path_lookup" do
    let(:codeowner_lookup_ref) { merge_request.target_branch }
    let(:codeowner_content) { 'files/ruby/feature.rb @owner-1' }
    let(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    before do
      stub_licensed_features(code_owners: true)
    end

    it "return equivalent results" do
      fast_results = described_class.entries_for_merge_request(merge_request).first

      expect(merge_request.merge_request_diff).to receive(:overflow?).and_return(true)

      slow_results = described_class.entries_for_merge_request(merge_request).first

      expect(slow_results.users).to eq(fast_results.users)
      expect(slow_results.groups).to eq(fast_results.groups)
      expect(slow_results.pattern).to eq(fast_results.pattern)
    end
  end

  describe '.entries_for_merge_request' do
    let(:codeowner_lookup_ref) { merge_request.target_branch }
    let(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: 'feature',
        target_project: project,
        target_branch: 'with-codeowners'
      )
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(code_owners: true)
      end

      it 'returns owners for merge request' do
        expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: nil).and_return(['docs/CODEOWNERS'])

        entry = described_class.entries_for_merge_request(merge_request).first

        expect(entry.pattern).to eq('docs/CODEOWNERS')
        expect(entry.users).to eq([code_owner])
      end

      context 'when merge_request_diff is specified' do
        it 'returns owners at the specified ref' do
          expect(described_class).to receive(:fast_path_lookup).and_call_original
          expect(merge_request).to receive(:modified_paths).with(past_merge_request_diff: merge_request.merge_request_diff).and_return(['docs/CODEOWNERS'])

          entry = described_class.entries_for_merge_request(merge_request, merge_request_diff: merge_request.merge_request_diff).first

          expect(entry.users).to eq([code_owner])
        end
      end

      context 'when the merge request is large (>1_000 files)' do
        before do
          expect(merge_request.merge_request_diff).to receive(:overflow?).and_return(true)
        end

        it 'generates paths via .slow_path_lookup' do
          expect(described_class).not_to receive(:fast_path_lookup)
          expect(described_class).to receive(:slow_path_lookup).and_call_original

          described_class.entries_for_merge_request(merge_request)
        end
      end
    end

    context 'when the feature is not available' do
      before do
        stub_licensed_features(code_owners: false)
      end

      it 'skips reading codeowners and returns an empty array' do
        expect(described_class).not_to receive(:loader_for_merge_request)

        expect(described_class.entries_for_merge_request(merge_request)).to eq([])
      end
    end
  end
end
