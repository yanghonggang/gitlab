# frozen_string_literal: true

module EE
  module Members
    module DestroyService
      def after_execute(member:)
        super

        if system_event? && removed_due_to_expiry?(member)
          log_audit_event(member: member, author: nil, action: :expired)
        else
          log_audit_event(member: member, author: current_user, action: :destroy)
        end

        cleanup_group_identity(member)
        cleanup_group_deletion_schedule(member) if member.source&.is_a?(Group)
      end

      private

      def removed_due_to_expiry?(member)
        member.expired?
      end

      def system_event?
        current_user.blank?
      end

      def log_audit_event(member:, author:, action:)
        ::AuditEventService.new(
          author,
          member.source,
          action: action
        ).for_member(member).security_event
      end

      def cleanup_group_identity(member)
        saml_provider = member.source.try(:saml_provider)

        return unless saml_provider

        saml_provider.identities.for_user(member.user).delete_all
      end

      def cleanup_group_deletion_schedule(member)
        deletion_schedule = member.source&.deletion_schedule

        return unless deletion_schedule

        deletion_schedule.destroy if deletion_schedule.deleting_user == member.user
      end
    end
  end
end
