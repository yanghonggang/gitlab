# frozen_string_literal: true

module Users
  class RejectService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not allowed to reject a user')) unless allowed?
      return error(_('This user does not have a pending request')) unless user.blocked_pending_approval?

      user_data = Users::DestroyService.new(current_user).execute(user, hard_delete: true)

      if user_data.destroyed?
        NotificationService.new.user_admin_rejection(user_data.name, user_data.email)
        success
      else
        error(user.errors.full_messages.uniq.join('. '))
      end
    end

    private

    attr_reader :current_user

    def allowed?
      can?(current_user, :reject_user)
    end
  end
end
