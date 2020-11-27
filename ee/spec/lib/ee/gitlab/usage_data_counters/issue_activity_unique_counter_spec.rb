# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::IssueActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:user1) { build(:user, id: 1) }
  let(:user2) { build(:user, id: 2) }
  let(:user3) { build(:user, id: 3) }
  let(:time) { Time.zone.now }

  context 'for Issue health status changed actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_HEALTH_STATUS_CHANGED }

      def track_action(params)
        described_class.track_issue_health_status_changed_action(**params)
      end
    end
  end

  context 'for Issue iteration changed actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_ITERATION_CHANGED }

      def track_action(params)
        described_class.track_issue_iteration_changed_action(**params)
      end
    end
  end

  context 'for Issue weight changed actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_WEIGHT_CHANGED }

      def track_action(params)
        described_class.track_issue_weight_changed_action(**params)
      end
    end
  end

  context 'for Issue added to epic actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_ADDED_TO_EPIC}

      def track_action(params)
        described_class.track_issue_added_to_epic_action(**params)
      end
    end
  end

  context 'for Issue removed from epic actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_REMOVED_FROM_EPIC}

      def track_action(params)
        described_class.track_issue_removed_from_epic_action(**params)
      end
    end
  end

  context 'for Issue changed epic actions' do
    it_behaves_like 'a tracked issue edit event' do
      let(:action) { described_class::ISSUE_CHANGED_EPIC}

      def track_action(params)
        described_class.track_issue_changed_epic_action(**params)
      end
    end
  end
end
