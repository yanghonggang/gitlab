# frozen_string_literal: true

module Deployments
  class AutoRollbackService < ::BaseService
    def execute(environment)
      result = validate(environment)
      return result unless result[:status] == :success

      deployment = find_rollback_target(environment)
      return error('Failed to find a rollback target.') unless deployment

      new_deployment = rollback_to(deployment)
      success(deployment: new_deployment)
    end

    private

    def validate(environment)
      unless environment.auto_rollback_enabled?
        return error('Auto Rollback is not enabled on the project.')
      end

      if environment.has_running_deployments?
        return error('There are running deployments on the environment.')
      end

      if ::Gitlab::ApplicationRateLimiter.throttled?(:auto_rollback_deployment, scope: [environment])
        return error('Auto Rollback was recentlly trigged for the environment. It will be re-activated after a minute.')
      end

      success
    end

    def find_rollback_target(environment)
      current_deployment = environment.last_deployment
      return unless current_deployment

      previous_commit_ids = current_deployment.commit&.parent_ids
      return unless previous_commit_ids

      rollback_target = environment.successful_deployments
        .with_deployable
        .latest_for_sha(previous_commit_ids)

      return unless rollback_target && rollback_target.deployable.retryable?

      rollback_target
    end

    def rollback_to(deployment)
      Ci::Build.retry(deployment.deployable, deployment.deployed_by).deployment
    end
  end
end
