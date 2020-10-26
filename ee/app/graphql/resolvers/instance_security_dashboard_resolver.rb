# frozen_string_literal: true

module Resolvers
  class InstanceSecurityDashboardResolver < BaseResolver
    type ::Types::InstanceSecurityDashboardType, null: true

    def resolve(**args)
      ::InstanceSecurityDashboard.new(current_user, project_ids: project_ids)
    end

    private

    def project_ids
      return [] unless object.is_a?(Project)

      [object.id]
    end
  end
end
