# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::UserProjectAccessChangedService do
  let(:service) { UserProjectAccessChangedService.new([1, 2]) }

  describe '#execute' do
    before do
      allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)

      expect(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
                                            .with([[1], [2]])
                                            .and_return(10)
    end

    it 'sticks all the updated users and returns the original result', :aggregate_failures do
      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:bulk_stick).with(:user, [1, 2])

      expect(service.execute).to eq(10)
    end

    it 'avoids N+1 cached queries', :use_sql_query_cache, :request_store do
      # Run this once to establish a baseline
      control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        service.execute
      end

      service = UserProjectAccessChangedService.new([1, 2, 3, 4, 5])

      allow(AuthorizedProjectsWorker).to receive(:bulk_perform_and_wait)
                                            .with([[1], [2], [3], [4], [5]])
                                            .and_return(10)

      expect { service.execute }.not_to exceed_all_query_limit(control_count.count)
    end
  end
end
