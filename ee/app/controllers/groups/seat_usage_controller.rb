# frozen_string_literal: true

class Groups::SeatUsageController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :verify_namespace_plan_check_enabled

  layout "group_settings"

  feature_category :purchase

  def show
    render_404 unless Feature.enabled?(:api_billable_member_list, @group)
  end
end
