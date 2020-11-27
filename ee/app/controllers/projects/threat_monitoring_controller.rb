# frozen_string_literal: true

module Projects
  class ThreatMonitoringController < Projects::ApplicationController
    before_action :authorize_read_threat_monitoring!
    before_action do
      push_frontend_feature_flag(:threat_monitoring_alerts, project)
    end

    feature_category :web_firewall

    def edit
      @environment = project.environments.find(params[:environment_id])
      @policy_name = params[:id]
      response = NetworkPolicies::FindResourceService.new(
        resource_name: @policy_name,
        environment: @environment,
        kind: Gitlab::Kubernetes::CiliumNetworkPolicy::KIND
      ).execute

      if response.success?
        @policy = response.payload
      else
        render_404
      end
    end
  end
end
