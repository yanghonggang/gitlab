# frozen_string_literal: true

module EE
  module Admin
    module ApplicationSettingsController
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      prepended do
        before_action :elasticsearch_reindexing_task, only: [:general]

        feature_category :provision, [:seat_link_payload]
        feature_category :source_code_management, [:templates]

        def elasticsearch_reindexing_task
          @elasticsearch_reindexing_task = Elastic::ReindexingTask.last
        end
      end

      EE_VALID_SETTING_PANELS = %w(templates).freeze

      EE_VALID_SETTING_PANELS.each do |action|
        define_method(action) { perform_update if submitted? }
      end

      def visible_application_setting_attributes
        attrs = super

        if License.feature_available?(:repository_mirrors)
          attrs += EE::ApplicationSettingsHelper.repository_mirror_attributes
        end

        # License feature => attribute name
        {
          custom_project_templates: :custom_project_templates_group_id,
          email_additional_text: :email_additional_text,
          custom_file_templates: :file_template_project_id,
          pseudonymizer: :pseudonymizer_enabled,
          default_project_deletion_protection: :default_project_deletion_protection,
          adjourned_deletion_for_projects_and_groups: :deletion_adjourned_period,
          required_ci_templates: :required_instance_ci_template,
          disable_name_update_for_users: :updating_name_disabled_for_users,
          package_forwarding: :npm_package_requests_forwarding,
          default_branch_protection_restriction_in_groups: :group_owners_can_manage_default_branch_protection
        }.each do |license_feature, attribute_name|
          if License.feature_available?(license_feature)
            attrs << attribute_name
          end
        end

        if License.feature_available?(:admin_merge_request_approvers_rules)
          attrs += EE::ApplicationSettingsHelper.merge_request_appovers_rules_attributes
        end

        if ::Gitlab::Geo.license_allows? && ::Feature.enabled?(:maintenance_mode)
          attrs << :maintenance_mode
          attrs << :maintenance_mode_message
        end

        attrs << :new_user_signups_cap if ::Feature.enabled?(:admin_new_user_signups_cap)

        attrs
      end

      def seat_link_payload
        data = ::Gitlab::SeatLinkData.new

        respond_to do |format|
          format.html do
            seat_link_json = ::Gitlab::Json.pretty_generate(data)

            render html: ::Gitlab::Highlight.highlight('payload.json', seat_link_json, language: 'json')
          end
          format.json { render json: data.to_json }
        end
      end

      private

      override :valid_setting_panels
      def valid_setting_panels
        super + EE_VALID_SETTING_PANELS
      end
    end
  end
end
