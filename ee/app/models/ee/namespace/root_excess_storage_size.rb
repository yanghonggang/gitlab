# frozen_string_literal: true

module EE
  class Namespace::RootExcessStorageSize
    include ::Gitlab::Utils::StrongMemoize

    def initialize(root_namespace)
      @root_namespace = root_namespace
    end

    def above_size_limit?
      return false unless enforce_limit?

      current_size > limit
    end

    def usage_ratio
      return 1 if limit == 0 && current_size > 0
      return 0 if limit == 0

      BigDecimal(current_size) / BigDecimal(limit)
    end

    def current_size
      strong_memoize(:current_size) { root_namespace.total_repository_size_excess }
    end

    def limit
      strong_memoize(:limit) do
        root_namespace.additional_purchased_storage_size.megabytes
      end
    end

    def enforce_limit?
      root_namespace.additional_repo_storage_by_namespace_enabled?
    end

    private

    attr_reader :root_namespace
  end
end
