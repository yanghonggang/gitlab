# frozen_string_literal: true

module Gitlab
  module RepositorySizeChecker
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    override :above_size_limit?
    def above_size_limit?
      return false unless enabled?
      return false if additional_repo_storage_available? && total_repository_size_excess <= additional_purchased_storage

      super
    end

    override :exceeded_size
    # @param change_size [int] in bytes
    def exceeded_size(change_size = 0)
      exceeded_size = super
      exceeded_size -= remaining_additional_purchased_storage if additional_repo_storage_available?
      exceeded_size
    end

    private

    def additional_repo_storage_available?
      return false unless Gitlab::CurrentSettings.automatic_purchased_storage_allocation?

      Feature.enabled?(:additional_repo_storage_by_namespace)
    end

    def remaining_additional_purchased_storage
      additional_purchased_storage - total_repository_size_excess
    end
  end
end
