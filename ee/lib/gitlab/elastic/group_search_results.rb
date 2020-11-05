# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class GroupSearchResults < Gitlab::Elastic::SearchResults
      attr_reader :group, :default_project_filter, :filters

      # rubocop:disable Metrics/ParameterLists
      def initialize(current_user, query, limit_project_ids = nil, group:, public_and_internal_projects: false, default_project_filter: false, order_by: nil, sort: nil, filters: {})
        @group = group
        @default_project_filter = default_project_filter
        @filters = filters

        super(current_user, query, limit_project_ids, public_and_internal_projects: public_and_internal_projects, order_by: order_by, sort: sort, filters: filters)
      end
      # rubocop:enable Metrics/ParameterLists
    end
  end
end
