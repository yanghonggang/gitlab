class AdminUserEntity < Grape::Entity
  include RequestAwareEntity
  include UsersHelper

  expose :id
  expose :name
  expose :created_at
  expose :email
  expose :username
  expose :last_activity_on
  expose :avatar_url
  expose :badges do |user|
    user_badges_in_admin_section(user)
  end

  expose :projects_count do |user|
    user.authorized_projects.length
  end

  expose :actions do |user|
    admin_actions(user)
  end

  # expose :actions do |user| 
  #   {
  #     internal: user.internal?,
  #     current_user: current_user,
  #     ldap_blocked: user.ldap_blocked?,
  #     blocked: user.blocked?
  #     blocked_pending_approval: user.blocked_pending_approval?
  #     can_be_deactivated: user.can_be_deactivated?
  #     deactivated: user.deactivated?,
  #     access_locked: user.access_locked?,
  #     can_be_removed: user.can_be_removed?
  #   }
  # end

  private

  def current_user
    options[:current_user]
  end
end