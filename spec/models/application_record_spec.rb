# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationRecord do
  describe '#id_in' do
    let(:records) { create_list(:user, 3) }

    it 'returns records of the ids' do
      expect(User.id_in(records.last(2).map(&:id))).to eq(records.last(2))
    end
  end

  describe '.safe_ensure_unique' do
    let(:model) { build(:suggestion) }
    let(:klass) { model.class }

    before do
      allow(model).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)
    end

    it 'returns false when ActiveRecord::RecordNotUnique is raised' do
      expect(model).to receive(:save).once
      expect(klass.safe_ensure_unique { model.save }).to be_falsey
    end

    it 'retries based on retry count specified' do
      expect(model).to receive(:save).exactly(3).times
      expect(klass.safe_ensure_unique(retries: 2) { model.save }).to be_falsey
    end
  end

  context 'safe find or create methods' do
    let_it_be(:note) { create(:diff_note_on_merge_request) }

    let(:suggestion_attributes) { attributes_for(:suggestion).merge!(note_id: note.id) }

    describe '.safe_find_or_create_by' do
      it 'creates the suggestion avoiding race conditions' do
        expect(Suggestion).to receive(:find_or_create_by).and_raise(ActiveRecord::RecordNotUnique)
        allow(Suggestion).to receive(:find_or_create_by).and_call_original

        expect { Suggestion.safe_find_or_create_by(suggestion_attributes) }
          .to change { Suggestion.count }.by(1)
      end

      it 'passes a block to find_or_create_by' do
        expect do |block|
          Suggestion.safe_find_or_create_by(suggestion_attributes, &block)
        end.to yield_with_args(an_object_having_attributes(suggestion_attributes))
      end

      it 'does not create a record when is not valid' do
        raw_usage_data = RawUsageData.safe_find_or_create_by({ recorded_at: nil })

        expect(raw_usage_data.id).to be_nil
        expect(raw_usage_data).not_to be_valid
      end
    end

    describe '.safe_find_or_create_by!' do
      it 'creates a record using safe_find_or_create_by' do
        expect(Suggestion).to receive(:find_or_create_by).and_call_original

        expect(Suggestion.safe_find_or_create_by!(suggestion_attributes))
          .to be_a(Suggestion)
      end

      it 'raises a validation error if the record was not persisted' do
        expect { Suggestion.safe_find_or_create_by!(note: nil) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'passes a block to find_or_create_by' do
        expect do |block|
          Suggestion.safe_find_or_create_by!(suggestion_attributes, &block)
        end.to yield_with_args(an_object_having_attributes(suggestion_attributes))
      end

      it 'raises a record not found error in case of attributes mismatch' do
        suggestion = Suggestion.safe_find_or_create_by!(suggestion_attributes)
        attributes = suggestion_attributes.merge(outdated: !suggestion.outdated)

        expect { Suggestion.safe_find_or_create_by!(attributes) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.underscore' do
    it 'returns the underscored value of the class as a string' do
      expect(MergeRequest.underscore).to eq('merge_request')
    end
  end

  describe '.at_most' do
    it 'limits the number of records returned' do
      create_list(:user, 3)
      expect(User.at_most(2).count).to eq(2)
    end
  end

  describe '.where_exists' do
    it 'produces a WHERE EXISTS query' do
      user = create(:user)

      expect(User.where_exists(User.limit(1))).to eq([user])
    end
  end
end
