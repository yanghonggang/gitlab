# frozen_string_literal: true

module EE
  module Snippet
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include Elastic::SnippetsSearch
      include UsageStatistics
    end

    override :repository_size_checker
    def repository_size_checker
      strong_memoize(:repository_size_checker) do
        ::Gitlab::RepositorySizeChecker.new(
          current_size_proc: -> { repository.size.megabytes },
          limit: ::Gitlab::CurrentSettings.snippet_size_limit,
          namespace: project&.namespace
        )
      end
    end
  end
end
