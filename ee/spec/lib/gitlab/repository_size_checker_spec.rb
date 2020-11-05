# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySizeChecker do
  let(:current_size) { 0 }
  let(:limit) { 50 }
  let(:total_repository_size_excess) { 0 }
  let(:additional_purchased_storage) { 0 }
  let(:enabled) { true }
  let(:gitlab_setting_enabled) { true }

  subject do
    described_class.new(
      current_size_proc: -> { current_size },
      limit: limit,
      total_repository_size_excess: total_repository_size_excess,
      additional_purchased_storage: additional_purchased_storage,
      enabled: enabled
    )
  end

  before do
    allow(Gitlab::CurrentSettings).to receive(:automatic_purchased_storage_allocation?).and_return(gitlab_setting_enabled)
  end

  describe '#above_size_limit?' do
    context 'when Gitlab app setting for automatic purchased storage allocation is not enabled' do
      let(:gitlab_setting_enabled) { false }

      include_examples 'checker size above limit'
      include_examples 'checker size not over limit'
    end

    context 'with feature flag :additional_repo_storage_by_namespace enabled' do
      context 'when there is available excess storage' do
        it 'returns false' do
          expect(subject.above_size_limit?).to eq(false)
        end
      end

      context 'when size is above the limit and there is no exccess storage' do
        let(:current_size) { 100 }
        let(:total_repository_size_excess) { 20 }
        let(:additional_purchased_storage) { 10 }

        it 'returns true' do
          expect(subject.above_size_limit?).to eq(true)
        end
      end

      it 'returns false when not over the limit' do
        expect(subject.above_size_limit?).to eq(false)
      end
    end

    context 'with feature flag :additional_repo_storage_by_namespace disabled' do
      before do
        stub_feature_flags(additional_repo_storage_by_namespace: false)
      end

      include_examples 'checker size above limit'
      include_examples 'checker size not over limit'
    end
  end

  describe '#exceeded_size' do
    context 'with feature flag :additional_repo_storage_by_namespace enabled' do
      context 'when Gitlab app setting for automatic purchased storage allocation is not enabled' do
        let(:gitlab_setting_enabled) { false }

        include_examples 'checker size exceeded'
      end

      context 'when current size + total repository size excess are below or equal to the limit + additional purchased storage' do
        let(:current_size) { 50 }
        let(:total_repository_size_excess) { 10 }
        let(:additional_purchased_storage) { 10 }

        it 'returns zero' do
          expect(subject.exceeded_size).to eq(0)
        end
      end

      context 'when current size + total repository size excess are over the limit + additional purchased storage' do
        let(:current_size) { 51 }
        let(:total_repository_size_excess) { 10 }
        let(:additional_purchased_storage) { 10 }

        it 'returns 1' do
          expect(subject.exceeded_size).to eq(1)
        end
      end

      context 'when change size will be over the limit' do
        let(:current_size) { 50 }

        it 'returns 1' do
          expect(subject.exceeded_size(1)).to eq(1)
        end
      end

      context 'when change size will not be over the limit' do
        let(:current_size) { 49 }

        it 'returns zero' do
          expect(subject.exceeded_size(1)).to eq(0)
        end
      end
    end

    context 'with feature flag :additional_repo_storage_by_namespace disabled' do
      before do
        stub_feature_flags(additional_repo_storage_by_namespace: false)
      end

      include_examples 'checker size exceeded'
    end
  end
end
