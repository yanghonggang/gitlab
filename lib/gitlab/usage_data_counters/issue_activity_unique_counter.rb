# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module IssueActivityUniqueCounter
      ISSUE_CATEGORY = 'issues_edit'

      ISSUE_ASSIGNEE_CHANGED = 'g_project_management_issue_assignee_changed'
      ISSUE_CREATED = 'g_project_management_issue_created'
      ISSUE_CLOSED = 'g_project_management_issue_closed'
      ISSUE_DESCRIPTION_CHANGED = 'g_project_management_issue_description_changed'
      ISSUE_ITERATION_CHANGED = 'g_project_management_issue_iteration_changed'
      ISSUE_LABEL_CHANGED = 'g_project_management_issue_label_changed'
      ISSUE_MADE_CONFIDENTIAL = 'g_project_management_issue_made_confidential'
      ISSUE_MADE_VISIBLE = 'g_project_management_issue_made_visible'
      ISSUE_MILESTONE_CHANGED = 'g_project_management_issue_milestone_changed'
      ISSUE_REOPENED = 'g_project_management_issue_reopened'
      ISSUE_TITLE_CHANGED = 'g_project_management_issue_title_changed'
      ISSUE_WEIGHT_CHANGED = 'g_project_management_issue_weight_changed'
      ISSUE_CROSS_REFERENCED = 'g_project_management_issue_cross_referenced'
      ISSUE_MOVED = 'g_project_management_issue_moved'
      ISSUE_RELATED = 'g_project_management_issue_related'
      ISSUE_UNRELATED = 'g_project_management_issue_unrelated'
      ISSUE_MARKED_AS_DUPLICATE = 'g_project_management_issue_marked_as_duplicate'
      ISSUE_LOCKED = 'g_project_management_issue_locked'
      ISSUE_UNLOCKED = 'g_project_management_issue_unlocked'
      ISSUE_ADDED_TO_EPIC = 'g_project_management_issue_added_to_epic'
      ISSUE_REMOVED_FROM_EPIC = 'g_project_management_issue_removed_from_epic'
      ISSUE_CHANGED_EPIC = 'g_project_management_issue_changed_epic'

      class << self
        def track_issue_created_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CREATED, author, time)
        end

        def track_issue_title_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_TITLE_CHANGED, author, time)
        end

        def track_issue_description_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_DESCRIPTION_CHANGED, author, time)
        end

        def track_issue_assignee_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_ASSIGNEE_CHANGED, author, time)
        end

        def track_issue_made_confidential_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MADE_CONFIDENTIAL, author, time)
        end

        def track_issue_made_visible_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MADE_VISIBLE, author, time)
        end

        def track_issue_closed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CLOSED, author, time)
        end

        def track_issue_reopened_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_REOPENED, author, time)
        end

        def track_issue_label_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_LABEL_CHANGED, author, time)
        end

        def track_issue_milestone_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MILESTONE_CHANGED, author, time)
        end

        def track_issue_iteration_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_ITERATION_CHANGED, author, time)
        end

        def track_issue_weight_changed_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_WEIGHT_CHANGED, author, time)
        end

        def track_issue_cross_referenced_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CROSS_REFERENCED, author, time)
        end

        def track_issue_moved_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MOVED, author, time)
        end

        def track_issue_related_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_RELATED, author, time)
        end

        def track_issue_unrelated_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_UNRELATED, author, time)
        end

        def track_issue_marked_as_duplicate_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_MARKED_AS_DUPLICATE, author, time)
        end

        def track_issue_locked_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_LOCKED, author, time)
        end

        def track_issue_unlocked_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_UNLOCKED, author, time)
        end

        def track_issue_added_to_epic_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_ADDED_TO_EPIC, author, time)
        end

        def track_issue_removed_from_epic_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_REMOVED_FROM_EPIC, author, time)
        end

        def track_issue_changed_epic_action(author:, time: Time.zone.now)
          track_unique_action(ISSUE_CHANGED_EPIC, author, time)
        end

        private

        def track_unique_action(action, author, time)
          return unless Feature.enabled?(:track_issue_activity_actions, default_enabled: true)
          return unless author

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(author.id, action, time)
        end
      end
    end
  end
end
