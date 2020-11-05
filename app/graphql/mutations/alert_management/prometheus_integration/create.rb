# frozen_string_literal: true

module Mutations
  module AlertManagement
    module PrometheusIntegration
      class Create < PrometheusIntegrationBase
        include ResolvesProject

        graphql_name 'PrometheusIntegrationCreate'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'The project to create the integration in'

        argument :active, GraphQL::BOOLEAN_TYPE,
                 required: true,
                 description: 'Whether the integration is receiving alerts'

        argument :api_url, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'Endpoint at which prometheus can be queried'

        def resolve(args)
          project = authorized_find!(full_path: args[:project_path])

          return integration_exists if project.prometheus_service

          result = ::Projects::Operations::UpdateService.new(
            project,
            current_user,
            **integration_attributes(args),
            **token_attributes
          ).execute

          response(project.prometheus_service, result)
        end

        private

        def find_object(full_path:)
          resolve_project(full_path: full_path)
        end

        def integration_exists
          response(nil, message: _('Multiple Prometheus integrations are not supported'))
        end
      end
    end
  end
end
