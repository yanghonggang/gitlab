# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc _('Add to epic')
          explanation _('Adds an issue to an epic.')
          types Issue
          condition do
            quick_action_target.supports_epic? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          params '<&epic | group&epic | Epic URL>'
          command :epic do |epic_param|
            epic = extract_epic(epic_param)
            issue = quick_action_target

            message =
              if epic && current_user.can?(:read_epic, epic)
                if issue&.epic == epic
                  _('Issue %{issue_reference} has already been added to epic %{epic_reference}.') %
                    { issue_reference: issue.to_reference, epic_reference: epic.to_reference }
                else
                  @updates[:epic] = epic
                  _('Added an issue to an epic.')
                end
              else
                _("This epic does not exist or you don't have sufficient permission.")
              end

            @execution_message[:epic] = message
          end

          desc _('Remove from epic')
          explanation _('Removes an issue from an epic.')
          execution_message _('Removed an issue from an epic.')
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.supports_epic? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :remove_epic do
            @updates[:epic] = nil
          end

          promote_message = _('Promote issue to an epic')
          promote_message_confidential = _('Promote confidential issue to a non-confidential epic')

          desc do
            if quick_action_target.confidential?
              promote_message_confidential
            else
              promote_message
            end
          end
          explanation promote_message
          warning do
            if quick_action_target.confidential?
              promote_message_confidential
            end
          end
          icon 'confidential'
          types Issue
          condition do
            quick_action_target.can_be_promoted_to_epic?(current_user)
          end
          command :promote do
            @updates[:promote_to_epic] = true

            @execution_message[:promote] = if quick_action_target.confidential?
                                             _('Promoted confidential issue to a non-confidential epic. Information in this issue is no longer confidential as epics are public to group members.')
                                           else
                                             _('Promoted issue to an epic.')
                                           end
          end

          desc _('Set iteration')
          explanation do |iteration|
            _("Sets the iteration to %{iteration_reference}.") % { iteration_reference: iteration.to_reference } if iteration
          end
          execution_message do |iteration|
            _("Set the iteration to %{iteration_reference}.") % { iteration_reference: iteration.to_reference } if iteration
          end
          params '*iteration:"iteration name"'
          types Issue
          condition do
            quick_action_target.supports_iterations? &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project) &&
              quick_action_target.project.group&.feature_available?(:iterations) &&
              find_iterations(project, state: 'opened').any?
          end
          parse_params do |iteration_param|
            extract_references(iteration_param, :iteration).first ||
              find_iterations(project, title: iteration_param.strip, state: 'opened').first
          end
          command :iteration do |iteration|
            @updates[:iteration] = iteration if iteration
          end

          desc _('Remove iteration')
          explanation do
            _("Removes %{iteration_reference} iteration.") % { iteration_reference: quick_action_target.iteration.to_reference(format: :name) }
          end
          execution_message do
            _("Removed %{iteration_reference} iteration.") % { iteration_reference: quick_action_target.iteration.to_reference(format: :name) }
          end
          types Issue
          condition do
            quick_action_target.supports_iterations? &&
              quick_action_target.persisted? &&
              quick_action_target.sprint_id? &&
              quick_action_target.project.group&.feature_available?(:iterations) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
          end
          command :remove_iteration do
            @updates[:iteration] = nil
          end

          def extract_epic(params)
            return if params.nil?

            extract_references(params, :epic).first
          end

          def find_iterations(project, params = {})
            parent_params = ::IterationsFinder.params_for_parent(project, include_ancestors: true)

            ::IterationsFinder.new(current_user, params.merge(parent_params)).execute
          end

          desc _('Publish to status page')
          explanation _('Publishes this issue to the associated status page.')
          types Issue
          condition do
            StatusPage::MarkForPublicationService.publishable?(project, current_user, quick_action_target)
          end
          command :publish do
            if ::Gitlab::StatusPage.mark_for_publication(project, current_user, quick_action_target).success?
              ::Gitlab::StatusPage.trigger_publish(project, current_user, quick_action_target, action: :init)
              @execution_message[:publish] = _('Issue published on status page.')
            else
              @execution_message[:publish] = _('Failed to publish issue on status page.')
            end
          end
        end
      end
    end
  end
end
