module Gitlab
  class WardenSession
    KEY = 'gitlab.warden_sessions'.freeze

    class << self
      # Save current warden values for later use.
      def save
        current_user_id = session.dig('warden.user.user.key', 0, 0)
        saved[current_user_id] = warden_data if current_user_id
      end

      # Load saved warden values to active session.
      def load(user_id)
        session.merge!(saved[user_id]) if saved.has_key?(user_id)
      end

      def user_authorized?(user_id)
        saved.has_key?(user_id.to_i)
      end

      def authorized_users
        User.where(id: saved.keys)
      end

      def delete(user_id)
        saved.delete(user_id)
      end

      private

      # A slice of all warden data.
      def warden_data
        session.to_h.slice(*warden_keys)
      end

      def warden_keys
        session.keys.grep(/warden\./)
      end

      def saved
        session[KEY] ||= {}
      end

      def session
        Gitlab::Session.current
      end
    end
  end
end
