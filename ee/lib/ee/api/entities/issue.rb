# frozen_string_literal: true

module EE
  module API
    module Entities
      module Issue
        extend ActiveSupport::Concern

        prepended do
          with_options if: -> (issue, _) { issue.project.group&.feature_available?(:epics) } do
            expose :epic_iid do |issue|
              authorized_epic_for(issue)&.iid
            end

            expose :epic, using: EpicBaseEntity do |issue|
              authorized_epic_for(issue)
            end

            def authorized_epic_for(issue)
              issue.epic if ::Ability.allowed?(options[:current_user], :read_epic, issue.epic)
            end
          end
        end
      end
    end
  end
end
