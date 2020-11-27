# frozen_string_literal: true

module SecurityHelper
  def instance_security_dashboard_data
    {
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index', anchor: 'instance-security-dashboard'),
      no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
      empty_dashboard_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      empty_state_svg_path: image_path('illustrations/operations-dashboard_empty.svg'),
      project_add_endpoint: security_projects_path,
      project_list_endpoint: security_projects_path,
      instance_dashboard_settings_path: settings_security_dashboard_path,
      vulnerabilities_export_endpoint: expose_path(api_v4_security_vulnerability_exports_path)
    }
  end

  def security_dashboard_unavailable_view_data
    {
      empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
      is_unavailable: "true"
    }
  end
end
