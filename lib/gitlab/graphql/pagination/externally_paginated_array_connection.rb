# frozen_string_literal: true

# Make a customized connection type
module Gitlab
  module Graphql
    module Pagination
      class ExternallyPaginatedArrayConnection < GraphQL::Pagination::ArrayConnection
        include ::Gitlab::Graphql::ConnectionCollectionMethods
        include ::Gitlab::Graphql::ConnectionRedaction

        def start_cursor
          items.previous_cursor
        end

        def end_cursor
          items.next_cursor
        end

        def next_page?
          end_cursor.present?
        end

        def previous_page?
          start_cursor.present?
        end

        alias_method :has_next_page, :next_page?
        alias_method :has_previous_page, :previous_page?

        private

        def load_nodes
          @nodes ||= begin
            # As the pagination happens externally we just grab all the nodes
            limited_nodes = items

            limited_nodes = limited_nodes.first(first) if first
            limited_nodes = limited_nodes.last(last) if last

            limited_nodes
          end
        end
      end
    end
  end
end
