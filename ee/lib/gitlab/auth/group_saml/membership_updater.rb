# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class MembershipUpdater
        include Gitlab::Utils::StrongMemoize

        attr_reader :user, :saml_provider, :auth_hash

        delegate :group, :default_membership_role, to: :saml_provider

        def initialize(user, saml_provider, auth_hash)
          @user = user
          @saml_provider = saml_provider
          @auth_hash = AuthHash.new(auth_hash)
        end

        def execute
          update_default_membership
          enqueue_group_sync if sync_groups?
        end

        private

        def update_default_membership
          return if group.member?(user)

          member = group.add_user(user, default_membership_role)

          log_audit_event(member: member)
        end

        def enqueue_group_sync
          GroupSamlGroupSyncWorker.perform_async(user.id, group.id, group_link_ids)
        end

        def sync_groups?
          return false unless user && group.saml_group_sync_available?

          group_names_from_saml.any? && group_link_ids.any?
        end

        # rubocop:disable CodeReuse/ActiveRecord
        def group_link_ids
          strong_memoize(:group_link_ids) do
            SamlGroupLink
              .by_saml_group_name(group_names_from_saml)
              .by_group_id(group.self_and_descendants.select(:id))
              .pluck(:id)
          end
        end
        # rubocop:enable CodeReuse/ActiveRecord

        def group_names_from_saml
          strong_memoize(:group_names_from_saml) do
            auth_hash.groups
          end
        end

        def log_audit_event(member:)
          ::AuditEventService.new(
            user,
            member.source,
            action: :create
          ).for_member(member).security_event
        end
      end
    end
  end
end
