# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueAndMergeRequestActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc _('Change assignee(s)')
          explanation _('Change assignee(s).')
          execution_message _('Changed assignee(s).')
          params '@user1 @user2'
          types Issue, MergeRequest
          condition do
            quick_action_target.allows_multiple_assignees? &&
              quick_action_target.persisted? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
          end
          command :reassign do |reassign_param|
            @updates[:assignee_ids] = extract_users(reassign_param).map(&:id)
          end

          desc _('Change reviewer(s)')
          explanation _('Change reviewer(s).')
          execution_message _('Changed reviewer(s).')
          params '@user1 @user2'
          types MergeRequest
          condition do
            quick_action_target.allows_multiple_reviewers? &&
              quick_action_target.persisted? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project) &&
              ::Feature.enabled?(:merge_request_reviewers)
          end
          command :reassign_reviewer do |reassign_param|
            @updates[:reviewer_ids] = extract_users(reassign_param).map(&:id)
          end

          desc _('Set weight')
          explanation do |weight|
            _("Sets weight to %{weight}.") % { weight: weight } if weight
          end

          params "0, 1, 2, …"
          types Issue, MergeRequest
          condition do
            quick_action_target.weight_available? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          parse_params do |weight|
            weight.to_i if weight.to_i >= 0
          end
          command :weight do |weight|
            if weight
              @updates[:weight] = weight
              @execution_message[:weight] = _("Set weight to %{weight}.") % { weight: weight }
            end
          end

          desc _('Clear weight')
          explanation _('Clears weight.')
          execution_message _('Cleared weight.')
          types Issue, MergeRequest
          condition do
            quick_action_target.persisted? &&
              quick_action_target.weight_available? &&
              quick_action_target.weight? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :clear_weight do
            @updates[:weight] = nil
          end
        end
      end
    end
  end
end
