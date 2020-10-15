# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include IntegrationsActions
  include ServicesHelper

  before_action :not_found, unless: -> { instance_level_integrations? }

  feature_category :integrations

  private

  def find_or_initialize_integration(name)
    Service.find_or_initialize_integration(name, instance: true)
  end

  def scoped_edit_integration_path(integration)
    edit_admin_application_settings_integration_path(integration)
  end
end
