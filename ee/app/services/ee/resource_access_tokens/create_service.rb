# frozen_string_literal: true

module EE
  module ResourceAccessTokens
    module CreateService
      def execute
        super.tap do |response|
          log_audit_event(response.payload[:personal_access_token])
        end
      end

      private

      def log_audit_event(token)
        audit_event_service(token).for_user(full_path: target_user.username, entity_id: target_user.id).security_event
      end

      def audit_event_service(token)
        message = "Created project access token with id #{token.id}"


        ::AuditEventService.new(
          current_user,
          target_user,
          action: :custom,
          custom_message: message,
          ip_address: ip_address
        )
      end
    end
  end
end
