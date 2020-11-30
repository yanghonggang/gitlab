# frozen_string_literal: true

module Groups
  module Settings
    class ComplianceFrameworkLabelsController < Groups::ApplicationController
      before_action :authorize_admin_group!

      respond_to :html

      def new
      end

      def edit
      end
    end
  end
end
