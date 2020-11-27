# frozen_string_literal: true

class ApproveBlockedUsersWorker
  include ApplicationWorker

  idempotent!

  feature_category :users

  def perform(current_user_id)
    current_user = User.find(current_user_id)

    User.blocked_pending_approval.find_each do |user|
      Users::ApproveService.new(current_user).execute(user)
    end
  end
end
