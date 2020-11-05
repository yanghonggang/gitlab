# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::EventGapTracking, :clean_gitlab_redis_cache do
  let(:previous_event_id) { 7 }
  let(:gap_id) { previous_event_id + 1 }
  let(:event_id_with_gap) { previous_event_id + 2 }

  subject(:gap_tracking) { described_class.new }

  before do
    gap_tracking.previous_id = previous_event_id
  end

  describe '.min_gap_id' do
    it 'returns nil when there are no gaps' do
      expect(described_class.min_gap_id).to eq(nil)
    end

    it 'returns the lowest gap id' do
      travel_to(50.minutes.ago) do
        gap_tracking.previous_id = 18
        gap_tracking.send(:track_gaps, 20)
      end

      travel_to(40.minutes.ago) do
        gap_tracking.previous_id = 12
        gap_tracking.send(:track_gaps, 14)
      end

      expect(described_class.min_gap_id).to eq(13)
    end
  end

  describe '.gap_count' do
    it 'returns 0 when there are no gaps' do
      expect(described_class.gap_count).to be_zero
    end

    it 'returns the number of gaps' do
      gap_tracking.previous_id = 18
      gap_tracking.send(:track_gaps, 20)

      gap_tracking.previous_id = 12
      gap_tracking.send(:track_gaps, 14)

      expect(described_class.gap_count).to eq(2)
    end
  end

  describe '#check!' do
    it 'does nothing when previous id not valid' do
      gap_tracking.previous_id = 0

      expect(gap_tracking).not_to receive(:gap?)

      gap_tracking.check!(event_id_with_gap)

      expect(gap_tracking.previous_id).to eq(event_id_with_gap)
    end

    it 'does nothing when there is no gap' do
      expect(gap_tracking).not_to receive(:track_gaps)

      gap_tracking.check!(previous_event_id + 1)

      expect(gap_tracking.previous_id).to eq(previous_event_id + 1)
    end

    it 'tracks the gap if there is one' do
      expect(gap_tracking).to receive(:track_gaps)

      gap_tracking.check!(event_id_with_gap)

      expect(gap_tracking.previous_id).to eq(event_id_with_gap)
    end
  end

  describe '#fill_gaps' do
    it 'ignore gaps that are less than 10 minutes old' do
      freeze_time do
        gap_tracking.check!(event_id_with_gap)

        expect { |blk| gap_tracking.fill_gaps(&blk) }.not_to yield_with_args(anything)
      end
    end

    it 'handles gaps that are more than 10 minutes old' do
      gap_tracking.check!(event_id_with_gap)

      gap_event = create(:geo_event_log, id: gap_id)

      Timecop.travel(12.minutes) do
        expect { |blk| gap_tracking.fill_gaps(&blk) }.to yield_with_args(gap_event)
      end

      expect(read_gaps).to be_empty
    end

    it 'drops gaps older than 1 hour' do
      gap_tracking.check!(event_id_with_gap)

      Timecop.travel(62.minutes) do
        expect { |blk| gap_tracking.fill_gaps(&blk) }.not_to yield_with_args(anything)
      end

      expect(read_gaps).to be_empty
    end

    it 'avoids N+1 queries to fetch event logs and their associated events' do
      yielded = []

      blk = lambda do |event_log|
        event_log.event
        yielded << event_log
      end

      travel_to(13.minutes.ago) do
        gap_tracking.check!(event_id_with_gap)
      end
      create(:geo_event_log, :updated_event, id: gap_id)

      control_count = ActiveRecord::QueryRecorder.new do
        expect { gap_tracking.fill_gaps(&blk) }.to change { yielded.count }.by(1)
      end.count

      travel_to(12.minutes.ago) do
        gap_tracking.check!(event_id_with_gap + 3)
      end
      create(:geo_event_log, :updated_event, id: event_id_with_gap + 1)
      create(:geo_event_log, :updated_event, id: event_id_with_gap + 2)

      expect do
        expect { gap_tracking.fill_gaps(&blk) }.to change { yielded.count }.by(2)
      end.not_to exceed_query_limit(control_count)
    end
  end

  describe '#track_gaps' do
    it 'logs a message' do
      expect(gap_tracking).to receive(:log_info).with(/gap detected/, hash_including(previous_event_id: previous_event_id, current_event_id: event_id_with_gap))

      gap_tracking.send(:track_gaps, event_id_with_gap)
    end

    it 'saves the gap id in redis' do
      freeze_time do
        gap_tracking.send(:track_gaps, event_id_with_gap)

        expect(read_gaps).to contain_exactly([gap_id.to_s, Time.now.to_i])
      end
    end

    it 'saves a range of gaps id in redis' do
      freeze_time do
        gap_tracking.send(:track_gaps, event_id_with_gap + 3)

        expected_gaps = ((previous_event_id + 1)..(event_id_with_gap + 2)).collect { |id| [id.to_s, Time.now.to_i] }

        expect(read_gaps).to match_array(expected_gaps)
      end
    end

    it 'saves the gaps in order' do
      expected_gaps = []

      freeze_time do
        gap_tracking.send(:track_gaps, event_id_with_gap)
        expected_gaps << [gap_id.to_s, Time.now.to_i]
      end

      Timecop.travel(2.minutes) do
        gap_tracking.previous_id = 17
        gap_tracking.send(:track_gaps, 19)
        expected_gaps << [18.to_s, Time.now.to_i]
      end

      expect(read_gaps).to eq(expected_gaps)
    end
  end

  describe '#gap?' do
    it 'returns false when current_id is the previous +1' do
      expect(gap_tracking.send(:gap?, previous_event_id + 1)).to be_falsy
    end

    it 'returns true when current_id is the previous +2' do
      expect(gap_tracking.send(:gap?, previous_event_id + 2)).to be_truthy
    end

    it 'returns false when current_id is equal to the previous' do
      expect(gap_tracking.send(:gap?, previous_event_id)).to be_falsy
    end

    it 'returns false when current_id less than the previous' do
      expect(gap_tracking.send(:gap?, previous_event_id - 1)).to be_falsy
    end

    it 'returns false when previous id is 0' do
      gap_tracking.previous_id = 0

      expect(gap_tracking.send(:gap?, 100)).to be_falsy
    end
  end

  def read_gaps
    ::Gitlab::Redis::SharedState.with do |redis|
      redis.zrangebyscore(described_class::GEO_EVENT_LOG_GAPS, '-inf', '+inf', with_scores: true)
    end
  end
end
