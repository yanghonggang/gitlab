# frozen_string_literal: true

# EE extension of PostReceiveService class
module EE
  module PostReceiveService
    include ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      response = super

      response.add_basic_message(geo_redirect_to_primary_message) if display_geo_redirect_to_primary_message?
      response.add_basic_message(geo_secondary_lag_message) if geo_display_secondary_lag_message?

      response.add_alert_message(storage_size_limit_alert)

      response
    end

    private

    def geo_redirect_to_primary_message
      return unless geo_referred_node

      strong_memoize(:geo_redirect_to_primary_message) do
        url = "#{::Gitlab::Geo.current_node.url.chomp('/')}/#{project.full_path}.git"
        ::Gitlab::Geo.interacting_with_primary_message(url)
      end
    end

    def geo_referred_node
      strong_memoize(:geo_referred_node) do
        ::Gitlab::Geo::GitPushHttp.new(params[:identifier], params[:gl_repository]).fetch_referrer_node
      end
    end

    def geo_secondary_lag_message
      "Current replication lag: #{geo_current_replication_lag} seconds"
    end

    def geo_current_replication_lag
      strong_memoize(:geo_current_replication_lag) do
        geo_referred_node&.status&.db_replication_lag_seconds
      end
    end

    def display_geo_redirect_to_primary_message?
      ::Gitlab::Geo.primary? && geo_redirect_to_primary_message
    end

    def geo_display_secondary_lag_message?
      ::Gitlab::Geo.primary? && geo_current_replication_lag.to_i > 0
    end

    def storage_size_limit_alert
      return unless repository&.repo_type&.project?

      payload = check_storage_size_service(project.namespace).execute.payload
      return unless payload.present?

      alert_level = "##### #{payload[:alert_level].to_s.upcase} #####"

      [alert_level, payload[:usage_message], payload[:explanation_message]].join("\n")
    end

    def check_storage_size_service(namespace)
      if namespace.additional_repo_storage_by_namespace_enabled?
        ::Namespaces::CheckExcessStorageSizeService.new(namespace, user)
      else
        ::Namespaces::CheckStorageSizeService.new(namespace, user)
      end
    end
  end
end
