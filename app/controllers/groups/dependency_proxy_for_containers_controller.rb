# frozen_string_literal: true

class Groups::DependencyProxyForContainersController < Groups::ApplicationController
  include Groups::DependencyProxy::Access
  include DependencyProxy::Auth
  include SendFileUpload

  prepend_before_action :sign_in_user_from_token!
  before_action :ensure_token_granted!
  before_action :ensure_feature_enabled!

  attr_reader :token

  feature_category :dependency_proxy

  def manifest
    result = DependencyProxy::PullManifestService.new(image, tag, token).execute

    if result[:status] == :success
      render json: result[:manifest]
    else
      render status: result[:http_status], json: result[:message]
    end
  end

  def blob
    result = DependencyProxy::FindOrCreateBlobService
      .new(group, image, token, params[:sha]).execute

    if result[:status] == :success
      send_upload(result[:blob].file)
    else
      head result[:http_status]
    end
  end

  private

  def sign_in_user_from_token!
    return unless Feature.enabled?(:dependency_proxy_for_private_groups, default_enabled: false)
    return respond_unauthorized! unless request.headers['HTTP_AUTHORIZATION']

    user = user_from_token
    return respond_unauthorized! unless user

    sign_in(user)
  end

  def image
    params[:image]
  end

  def tag
    params[:tag]
  end

  def dependency_proxy
    @dependency_proxy ||=
      group.dependency_proxy_setting || group.create_dependency_proxy_setting
  end

  def ensure_feature_enabled!
    render_404 unless dependency_proxy.enabled
  end

  def ensure_token_granted!
    result = DependencyProxy::RequestTokenService.new(image).execute

    if result[:status] == :success
      @token = result[:token]
    else
      render status: result[:http_status], json: result[:message]
    end
  end
end
