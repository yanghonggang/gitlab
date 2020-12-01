# frozen_string_literal: true

class Groups::DependencyProxyAuthController < ApplicationController
  include DependencyProxy::Auth

  feature_category :dependency_proxy

  skip_before_action :authenticate_user!

  def authenticate
    render plain: '', status: :ok
  end
end
