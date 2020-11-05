# frozen_string_literal: true

module Mutations
  module DastSiteValidations
    class Create < BaseMutation
      include AuthorizesProject

      graphql_name 'DastSiteValidationCreate'

      field :id, ::Types::GlobalIDType[::DastSiteValidation],
            null: true,
            description: 'ID of the site validation.'

      field :status, ::Types::DastSiteProfileValidationStatusEnum,
            null: true,
            description: 'The current validation status.'

      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the site profile belongs to.'

      argument :dast_site_token_id, ::Types::GlobalIDType[::DastSiteToken],
               required: true,
               description: 'ID of the site token.'

      argument :validation_path, GraphQL::STRING_TYPE,
               required: true,
               description: 'The path to be requested during validation.'

      argument :strategy, ::Types::DastSiteValidationStrategyEnum,
               required: false,
               description: 'The validation strategy to be used.'

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, dast_site_token_id:, validation_path:, strategy: :text_file)
        project = authorized_find_project!(full_path: full_path)
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

        dast_site_token = dast_site_token_id.find

        response = ::DastSiteValidations::CreateService.new(
          container: project,
          params: {
            dast_site_token: dast_site_token,
            url_path: validation_path,
            validation_strategy: strategy
          }
        ).execute

        return error_response(response.errors) if response.error?

        success_response(response.payload)
      end

      private

      def allowed?(project)
        Feature.enabled?(:security_on_demand_scans_site_validation, project)
      end

      def error_response(errors)
        { errors: errors }
      end

      def success_response(dast_site_validation)
        { errors: [], id: dast_site_validation.to_global_id, status: dast_site_validation.state }
      end
    end
  end
end
