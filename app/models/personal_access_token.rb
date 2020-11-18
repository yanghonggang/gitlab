# frozen_string_literal: true

class PersonalAccessToken < ApplicationRecord
  include Expirable
  include TokenAuthenticatable
  include Sortable
  extend ::Gitlab::Utils::Override

  add_authentication_token_field :token, digest: true

  REDIS_EXPIRY_TIME = 3.minutes
  TOKEN_LENGTH = 20

  serialize :scopes, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :user

  before_save :ensure_token

  scope :active, -> { where("revoked = false AND (expires_at >= CURRENT_DATE OR expires_at IS NULL)") }
  scope :expiring_and_not_notified, ->(date) { where(["revoked = false AND expire_notification_delivered = false AND expires_at >= CURRENT_DATE AND expires_at <= ?", date]) }
  scope :expired_today_and_not_notified, -> { where(["revoked = false AND expires_at = CURRENT_DATE AND after_expiry_notification_delivered = false"]) }
  scope :inactive, -> { where("revoked = true OR expires_at < CURRENT_DATE") }
  scope :with_impersonation, -> { where(impersonation: true) }
  scope :without_impersonation, -> { where(impersonation: false) }
  scope :revoked, -> { where(revoked: true) }
  scope :not_revoked, -> { where(revoked: [false, nil]) }
  scope :for_user, -> (user) { where(user: user) }
  scope :for_users, -> (users) { where(user: users) }
  scope :preload_users, -> { preload(:user) }
  scope :order_expires_at_asc, -> { reorder(expires_at: :asc) }
  scope :order_expires_at_desc, -> { reorder(expires_at: :desc) }

  validates :scopes, presence: true
  validate :validate_scopes

  after_initialize :set_default_scopes, if: :persisted?

  def revoke!
    update!(revoked: true)
  end

  def active?
    !revoked? && !expired?
  end

  def self.redis_getdel(user_id)
    Gitlab::Redis::SharedState.with do |redis|
      redis_key = redis_shared_state_key(user_id)
      encrypted_token = redis.get(redis_key)
      redis.del(redis_key)

      begin
        Gitlab::CryptoHelper.aes256_gcm_decrypt(encrypted_token)
      rescue => ex
        logger.warn "Failed to decrypt #{self.name} value stored in Redis for key ##{redis_key}: #{ex.class}"
        encrypted_token
      end
    end
  end

  def self.redis_store!(user_id, token)
    encrypted_token = Gitlab::CryptoHelper.aes256_gcm_encrypt(token)

    Gitlab::Redis::SharedState.with do |redis|
      redis.set(redis_shared_state_key(user_id), encrypted_token, ex: REDIS_EXPIRY_TIME)
    end
  end

  override :simple_sorts
  def self.simple_sorts
    super.merge(
      {
        'expires_at_asc' => -> { order_expires_at_asc },
        'expires_at_desc' => -> { order_expires_at_desc }
      }
    )
  end

  protected

  def validate_scopes
    unless revoked || scopes.all? { |scope| Gitlab::Auth.all_available_scopes.include?(scope.to_sym) }
      errors.add :scopes, "can only contain available scopes"
    end
  end

  def set_default_scopes
    self.scopes = Gitlab::Auth::DEFAULT_SCOPES if self.scopes.empty?
  end

  def self.redis_shared_state_key(user_id)
    "gitlab:personal_access_token:#{user_id}"
  end
end

PersonalAccessToken.prepend_if_ee('EE::PersonalAccessToken')
