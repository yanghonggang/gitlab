# frozen_string_literal: true

module EE
  module Issuable
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    def supports_epic?
      is_a?(Issue) && issue_type_supports?(:epics) && project.group.present?
    end

    def supports_health_status?
      false
    end

    def supports_weight?
      false
    end

    def weight_available?
      supports_weight? && project&.feature_available?(:issue_weights)
    end

    def sla_available?
      return false unless ::IncidentManagement::IncidentSla.available_for?(project)

      supports_sla?
    end

    def supports_sla?
      incident?
    end
  end
end
