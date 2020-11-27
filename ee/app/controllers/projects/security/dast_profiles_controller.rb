# frozen_string_literal: true

module Projects
  module Security
    class DastProfilesController < Projects::ApplicationController
      before_action do
        authorize_read_on_demand_scans!
        push_frontend_feature_flag(:security_on_demand_scans_site_validation, @project)
        push_frontend_feature_flag(:security_on_demand_scans_http_header_validation, @project)
      end

      feature_category :dynamic_application_security_testing

      def show
      end
    end
  end
end
