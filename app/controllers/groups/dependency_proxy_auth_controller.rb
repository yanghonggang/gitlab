# frozen_string_literal: true

class Groups::DependencyProxyAuthController < ApplicationController
  include DependencyProxy::Auth

  feature_category :dependency_proxy

  skip_before_action :authenticate_user!

  def authorize
    if Feature.enabled?(:dependency_proxy_for_private_groups, default_enabled: false)
      if request.headers['HTTP_AUTHORIZATION']
        user = user_from_token
        return respond_unauthorized! unless user

        render plain: '', status: :ok
      else
        respond_unauthorized!
      end
    else
      render plain: '', status: :ok
    end
  end
end
