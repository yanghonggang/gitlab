# frozen_string_literal: true

module DependencyProxy::Auth
  extend ActiveSupport::Concern

  def respond_unauthorized!
    response.headers['WWW-Authenticate'] = ::DependencyProxy::Registry.authenticate_header
    render plain: '', status: :unauthorized
  end

  def user_from_token
    token = Doorkeeper::OAuth::Token.from_bearer_authorization(request)
    token_payload = DependencyProxy::AuthTokenService.decoded_token_payload(token)
    User.find(token_payload['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::ImmatureSignature
    nil
  end
end
