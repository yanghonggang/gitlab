# frozen_string_literal: true

module Mutations
  module DastSiteTokens
    class Create < BaseMutation
      include AuthorizesProject

      graphql_name 'DastSiteTokenCreate'

      field :id, ::Types::GlobalIDType[::DastSiteToken],
            null: true,
            description: 'ID of the site token.'

      field :token, GraphQL::STRING_TYPE,
            null: true,
            description: 'Token string.'

      field :status, Types::DastSiteProfileValidationStatusEnum,
            null: true,
            description: 'The current validation status of the target.'

      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the site token belongs to.'

      argument :target_url, GraphQL::STRING_TYPE,
               required: false,
               description: 'The URL of the target to be validated.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, target_url:)
        project = authorized_find_project!(full_path: full_path)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

        response = ::DastSiteTokens::CreateService.new(
          container: project,
          params: { target_url: target_url }
        ).execute

        return error_response(response.errors) if response.error?

        success_response(response.payload[:dast_site_token], response.payload[:status])
      end

      private

      def allowed?(project)
        Feature.enabled?(:security_on_demand_scans_site_validation, project)
      end

      def error_response(errors)
        { errors: errors }
      end

      def success_response(dast_site_token, status)
        { errors: [], id: dast_site_token.to_global_id, status: status, token: dast_site_token.token }
      end
    end
  end
end
