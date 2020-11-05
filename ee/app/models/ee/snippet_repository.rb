# frozen_string_literal: true

module EE
  module SnippetRepository
    extend ActiveSupport::Concern

    prepended do
      include ::Gitlab::Geo::ReplicableModel

      with_replicator Geo::SnippetRepositoryReplicator
    end

    class_methods do
      # @param primary_key_in [Range, SnippetRepository] arg to pass to primary_key_in scope
      # @return [ActiveRecord::Relation<SnippetRepository>] everything that should be synced to this node, restricted by primary key
      def replicables_for_current_secondary(primary_key_in)
        # Not implemented yet. Should be responsible for selective sync
        all
      end
    end

    # Geo checks this method in FrameworkRepositorySyncService to avoid
    # snapshotting repositories using object pools
    def pool_repository
      nil
    end
  end
end
