# frozen_string_literal: true

module Geo
  class VerificationWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    idempotent!
    loggable_arguments 0

    def perform(replicable_name, replicable_id)
      replicator = ::Gitlab::Geo::Replicator.for_replicable_params(replicable_name: replicable_name, replicable_id: replicable_id)

      replicator.calculate_checksum!
    rescue ActiveRecord::RecordNotFound
      log_error("Couldn't find the record, skipping", replicable_name: replicable_name, replicable_id: replicable_id)
    end
  end
end
