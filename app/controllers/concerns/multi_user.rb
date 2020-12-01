module MultiUser
  extend ActiveSupport::Concern

  class_methods do
    # Allow the current action to define a new warden session.
    # Retain the previous warden session if the current action does nothing.
    def multi_user_login(options)
      prepend_before_action :enable_multi_user_login, options
    end

    def multi_user_logout(options)
      prepend_before_action :enable_multi_user_logout, options
    end
  end

  def enable_multi_user_login
    @multi_user_action = :login
  end

  def enable_multi_user_logout
    @multi_user_action = :logout
  end

  # Call this method in an around filter to handle multi-user warden sessions.
  # Must be specified after session storage has been defined.
  def multi_user_handler(&blk)
    case @multi_user_action
    when :login
      wrap_login_action(&blk)
    when :logout
      wrap_logout_action(&blk)
    else
      blk.call
    end
  end

  private

  def wrap_login_action(&blk)
    begin
      # Archive and move the current warden session out of the way.
      if previous_user = current_user
        Gitlab::WardenSession.save
        sign_out(previous_user)
      end

      # Run the login action. An invalid login will raise an exception.
      blk.call

      # Save the new authorized user in to our register.
      Gitlab::WardenSession.save
    ensure
      # Load the previous active warden session if no new session.
      if current_user.nil? && previous_user
        Gitlab::WardenSession.load(previous_user.id)
        bypass_sign_in(previous_user)
      end
    end
  end

  def wrap_logout_action(&blk)
    Gitlab::WardenSession.delete(current_user.id)
    blk.call
  end
end
