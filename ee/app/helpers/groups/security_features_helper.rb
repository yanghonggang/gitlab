# frozen_string_literal: true

module Groups::SecurityFeaturesHelper
  def group_level_security_dashboard_available?(group)
    group.feature_available?(:security_dashboard)
  end

  def group_level_compliance_dashboard_available?(group)
    group.feature_available?(:group_level_compliance_dashboard) &&
    can?(current_user, :read_group_compliance_dashboard, group)
  end

  def authorize_compliance_dashboard!
    render_404 unless group_level_compliance_dashboard_available?(group)
  end

  def group_level_credentials_inventory_available?(group)
    can?(current_user, :read_group_credentials_inventory, group) &&
    group.feature_available?(:credentials_inventory) &&
    group.enforced_group_managed_accounts?
  end

  def primary_group_level_security_feature_path(group)
    if group_level_security_dashboard_available?(group)
      group_security_dashboard_path(group)
    elsif group_level_compliance_dashboard_available?(group)
      group_security_compliance_dashboard_path(group)
    elsif group_level_credentials_inventory_available?(group)
      group_security_credentials_path(group)
    end
  end

  def group_level_security_dashboard_data(group)
    {
      projects_endpoint: expose_url(api_v4_groups_projects_path(id: group.id)),
      group_full_path: group.full_path,
      no_vulnerabilities_svg_path: image_path('illustrations/issues.svg'),
      empty_state_svg_path: image_path('illustrations/security-dashboard-empty-state.svg'),
      dashboard_documentation: help_page_path('user/application_security/security_dashboard/index'),
      vulnerabilities_export_endpoint: expose_path(api_v4_security_groups_vulnerability_exports_path(id: group.id))
    }
  end
end
