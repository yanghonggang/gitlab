# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IssuesHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_issue_params_ee do
            optional :weight, type: Integer, desc: 'The weight of the issue'
            optional :epic_id, type: Integer, desc: 'The ID of an epic to associate the issue with'
            optional :epic_iid, type: Integer, desc: 'The IID of an epic to associate the issue with (deprecated)'
            mutually_exclusive :epic_id, :epic_iid
          end

          params :negatable_issue_filter_params_ee do
            optional :iteration_id, types: [Integer, String], integer_none_any: true,
                     desc: 'Return issues which are assigned to the iteration with the given ID'
            optional :iteration_title, type: String,
                     desc: 'Return issues which are assigned to the iteration with the given title'
            mutually_exclusive :iteration_id, :iteration_title
          end

          params :optional_issues_params_ee do
            optional :weight, types: [Integer, String], integer_none_any: true, desc: 'The weight of the issue'
            optional :epic_id, types: [Integer, String], integer_none_any: true, desc: 'The ID of an epic associated with the issues'
          end
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :update_params_at_least_one_of
          def update_params_at_least_one_of
            [*super, :weight, :epic_id, :epic_iid]
          end

          override :sort_options
          def sort_options
            [*super, 'weight']
          end
        end
      end
    end
  end
end
