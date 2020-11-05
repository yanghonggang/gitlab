# frozen_string_literal: true

module EE
  module Groups
    module UpdateService
      extend ::Gitlab::Utils::Override
      EE_SETTINGS_PARAMS = [:prevent_forking_outside_group].freeze

      override :execute
      def execute
        if changes_file_template_project_id?
          check_file_template_project_id_change!
          return false if group.errors.present?
        end

        handle_changes

        remove_insight_if_insight_project_absent

        return false if group.errors.present?

        super.tap { |success| log_audit_event if success }
      end

      private

      override :after_update
      def after_update
        super

        if group.saved_change_to_max_personal_access_token_lifetime?
          group.update_personal_access_tokens_lifetime
        end
      end

      override :before_assignment_hook
      def before_assignment_hook(group, params)
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        group.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit
      end

      override :remove_unallowed_params
      def remove_unallowed_params
        unless current_user&.admin?
          params.delete(:shared_runners_minutes_limit)
          params.delete(:extra_shared_runners_minutes_limit)
        end

        insight_project_id = params.dig(:insight_attributes, :project_id)
        if insight_project_id
          group_projects = ::GroupProjectsFinder.new(group: group, current_user: current_user, options: { only_owned: true, include_subgroups: true }).execute
          params.delete(:insight_attributes) unless group_projects.exists?(insight_project_id) # rubocop:disable CodeReuse/ActiveRecord
        end

        super
      end

      def changes_file_template_project_id?
        return false unless params.key?(:file_template_project_id)

        params[:file_template_project_id] != group.checked_file_template_project_id
      end

      def check_file_template_project_id_change!
        unless can?(current_user, :admin_group, group)
          group.errors.add(:file_template_project_id, s_('GroupSettings|cannot be changed by you'))
          return
        end

        # Clearing the current value is always permitted if you can admin the group
        return unless params[:file_template_project_id].present?

        # Ensure the user can see the new project, avoiding information disclosures
        return if file_template_project_visible?

        group.errors.add(:file_template_project_id, 'is invalid')
      end

      def file_template_project_visible?
        ::ProjectsFinder.new(
          current_user: current_user,
          project_ids_relation: [params[:file_template_project_id]]
        ).execute.exists?
      end

      def remove_insight_if_insight_project_absent
        if params.dig(:insight_attributes, :project_id) == ''
          params[:insight_attributes][:_destroy] = true
          params[:insight_attributes].delete(:project_id)
        end
      end

      override :handle_changes
      def handle_changes
        handle_allowed_email_domains_update
        handle_ip_restriction_update
        super
      end

      def handle_ip_restriction_update
        comma_separated_ranges = params.delete(:ip_restriction_ranges)

        return if comma_separated_ranges.nil?

        IpRestrictions::UpdateService.new(group, comma_separated_ranges).execute
      end

      def handle_allowed_email_domains_update
        return unless params.key?(:allowed_email_domains_list)

        comma_separated_domains = params.delete(:allowed_email_domains_list)

        AllowedEmailDomains::UpdateService.new(current_user, group, comma_separated_domains).execute
      end

      override :allowed_settings_params
      def allowed_settings_params
        @allowed_settings_params ||= super + EE_SETTINGS_PARAMS
      end

      def log_audit_event
        EE::Audit::GroupChangesAuditor.new(current_user, group).execute
      end
    end
  end
end
