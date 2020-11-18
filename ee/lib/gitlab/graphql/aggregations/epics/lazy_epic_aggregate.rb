# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        class LazyEpicAggregate
          include ::Gitlab::Graphql::Aggregations::Epics::Constants
          include ::Gitlab::Graphql::Deferred

          attr_reader :facet, :epic_id, :lazy_state

          PERMITTED_FACETS = [COUNT, WEIGHT_SUM].freeze

          # Because facets "count" and "weight_sum" share the same db query, but have a different graphql type object,
          # we can separate them and serve only the fields which are requested by the GraphQL query
          def initialize(query_ctx, epic_id, aggregate_facet, &block)
            @epic_id = epic_id

            error = validate_facet(aggregate_facet)
            if error
              raise ArgumentError.new("#{error}. Please specify either #{COUNT} or #{WEIGHT_SUM}")
            end

            @facet = aggregate_facet.to_sym

            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_epic_aggregate] ||= {
                pending_ids: Set.new,
                tree: {}
            }
            # Register this ID to be loaded later:
            @lazy_state[:pending_ids] << epic_id

            @block = block
          end

          # Return the loaded record, hitting the database if needed
          def epic_aggregate
            # Check if the record was already loaded:
            # load from tree by epic
            unless tree[@epic_id]
              load_records_into_tree
            end

            node = tree[@epic_id]
            object = aggregate_object(node)

            @block ? @block.call(node, object) : object
          end

          alias_method :execute, :epic_aggregate

          private

          def validate_facet(aggregate_facet)
            unless aggregate_facet.present?
              return "No aggregate facet provided."
            end

            unless PERMITTED_FACETS.include?(aggregate_facet.to_sym)
              "Invalid aggregate facet #{aggregate_facet} provided."
            end
          end

          def tree
            @lazy_state[:tree]
          end

          def load_records_into_tree
            # The record hasn't been loaded yet, so
            # hit the database with all pending IDs
            pending_ids = @lazy_state[:pending_ids].to_a

            # Fire off the db query and get the results (grouped by epic_id and facet)
            raw_epic_aggregates = Gitlab::Graphql::Loaders::BulkEpicAggregateLoader.new(epic_ids: pending_ids).execute
            create_epic_nodes(raw_epic_aggregates)
            @lazy_state[:pending_ids].clear
          end

          def create_epic_nodes(aggregate_records)
            aggregate_records.each do |epic_id, aggregates|
              next if aggregates.blank?

              tree[epic_id] = EpicNode.new(epic_id, aggregates)
            end

            relate_parents_and_children
          end

          def relate_parents_and_children
            tree.each do |_, node|
              parent = tree[node.parent_id]
              next if parent.nil?

              parent.children << node
            end
          end

          def aggregate_object(node)
            if @facet == COUNT
              node.aggregate_count
            else
              node.aggregate_weight_sum
            end
          end
        end
      end
    end
  end
end
