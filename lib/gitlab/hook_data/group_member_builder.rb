# frozen_string_literal: true

module Gitlab
  module HookData
    class GroupMemberBuilder < BaseBuilder
      alias_method :group_member, :object

      def build(event)
        event_data(event).merge(group_member_data)
      end

      private

      def group_member_data
        {
          group_name: group_member.group.name,
          group_path: group_member.group.path,
          group_id: group_member.group.id,
          user_username: group_member.user.username,
          user_name: group_member.user.name,
          user_email: group_member.user.email,
          user_id: group_member.user.id,
          group_access: group_member.human_access,
          created_at: group_member.created_at&.xmlschema,
          updated_at: group_member.updated_at&.xmlschema
        }
      end

      def event_data(event)
        event_name =  case event
                      when :create
                        'user_add_to_group'
                      when :destroy
                        'user_remove_from_group'
                      when :update
                        'user_update_for_group'
                      end

        { event_name: event_name }
      end
    end
  end
end

Gitlab::HookData::GroupMemberBuilder.prepend_if_ee('EE::Gitlab::HookData::GroupMemberBuilder')
