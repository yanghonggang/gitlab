# frozen_string_literal: true

module EE
  module Issues
    module BuildService
      extend ::Gitlab::Utils::Override

      def issue_params_from_template
        return {} unless project.feature_available?(:issuable_default_templates)

        { description: project.issues_template }
      end

      # Issue params can be built from 3 types of passed params,
      # They take precedence over eachother like this
      # passed params > discussion params > template params
      # The template params are filled in here, and might be overwritten by super
      override :build_issue_params
      def build_issue_params
        issue_params_from_template.merge(super)
      end

      override :allowed_issue_base_params
      def allowed_issue_base_params
        return super - [:issue_type] if params[:issue_type] == 'test_case'

        super
      end

      override :allowed_issue_admin_params
      def allowed_issue_admin_params
        return super + [:issue_type] if params[:issue_type] == 'test_case'

        super
      end
    end
  end
end
