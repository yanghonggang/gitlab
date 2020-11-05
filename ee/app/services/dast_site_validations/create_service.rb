# frozen_string_literal: true

module DastSiteValidations
  class CreateService < BaseContainerService
    def execute
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?
      return ServiceResponse.success(payload: existing_validation) if existing_validation

      dast_site_validation = create_validation!

      perform_async_validation(dast_site_validation)
    rescue ActiveRecord::RecordInvalid => err
      ServiceResponse.error(message: err.record.errors.full_messages)
    rescue KeyError => err
      ServiceResponse.error(message: err.message.capitalize)
    end

    private

    def allowed?
      container.feature_available?(:security_on_demand_scans) &&
        Feature.enabled?(:security_on_demand_scans_site_validation, container) &&
        dast_site_token.project == container
    end

    def dast_site_token
      @dast_site_token ||= params.fetch(:dast_site_token)
    end

    def url_path
      @url_path ||= params.fetch(:url_path)
    end

    def validation_strategy
      @validation_strategy ||= params.fetch(:validation_strategy)
    end

    def existing_validation
      @existing_validation ||= find_latest_successful_dast_site_validation
    end

    def url_base
      @url_base ||= DastSiteValidation.get_normalized_url_base(dast_site_token.url)
    end

    def find_latest_successful_dast_site_validation
      DastSiteValidationsFinder.new(
        project_id: container.id,
        state: :passed,
        url_base: url_base
      ).execute.first
    end

    def create_validation!
      DastSiteValidation.create!(
        dast_site_token: dast_site_token,
        url_path: url_path,
        validation_strategy: validation_strategy
      )
    end

    def perform_async_validation(dast_site_validation)
      jid = DastSiteValidationWorker.perform_async(dast_site_validation.id)

      unless jid.present?
        log_error(message: 'Unable to validate dast_site_validation', dast_site_validation_id: dast_site_validation.id)

        dast_site_validation.fail_op

        return ServiceResponse.error(message: 'Validation failed')
      end

      ServiceResponse.success(payload: dast_site_validation)
    end
  end
end
