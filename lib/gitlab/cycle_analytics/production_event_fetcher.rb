# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class ProductionEventFetcher < BaseEventFetcher
      include ProductionHelper

      def initialize(**kwargs)
        @projections = [issue_table[:title],
                        issue_table[:iid],
                        issue_table[:id],
                        issue_table[:created_at],
                        issue_table[:author_id],
                        routes_table[:path]]

        super(**kwargs)
      end

      private

      def serialize(event)
        AnalyticsIssueSerializer.new(serialization_context).represent(event)
      end

      def allowed_ids_finder_class
        IssuesFinder
      end
    end
  end
end
