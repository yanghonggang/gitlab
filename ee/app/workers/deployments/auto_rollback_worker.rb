# frozen_string_literal: true

module Deployments
  class AutoRollbackWorker
    include ApplicationWorker

    idempotent!
    feature_category :continuous_delivery
    queue_namespace :deployment

    def perform(environment_id)
      Environment.find_by_id(environment_id).try do |environment|
        Deployments::AutoRollbackService.new(environment.project, nil)
          .execute(environment)
      end
    end
  end
end
