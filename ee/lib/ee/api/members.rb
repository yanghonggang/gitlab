# frozen_string_literal: true

module EE
  module API
    module Members
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The ID of a group'
        end
        resource :groups, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          desc 'Overrides the access level of an LDAP group member.' do
            success Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          post ":id/members/:user_id/override" do
            member = find_member(params)

            updated_member = ::Members::UpdateService
              .new(current_user, { override: true })
              .execute(member, permission: :override)

            present_member(updated_member)
          end

          desc 'Remove an LDAP group member access level override.' do
            success Entities::Member
          end
          params do
            requires :user_id, type: Integer, desc: 'The user ID of the member'
          end
          delete ":id/members/:user_id/override" do
            member = find_member(params)

            updated_member = ::Members::UpdateService
              .new(current_user, { override: false })
              .execute(member, permission: :override)

            present_member(updated_member)
          end

          desc 'Gets a list of billable users of root group.' do
            success Entities::Member
          end
          params do
            use :pagination
            optional :search, type: String, desc: 'The exact name of the subscribed member'
            optional :sort, type: String, desc: 'The sorting option', values: Helpers::MembersHelpers.member_sort_options, default: 'name_asc'
          end
          get ":id/billable_members" do
            group = find_group!(params[:id])

            not_found! unless ::Feature.enabled?(:api_billable_member_list, group)

            bad_request!(nil) if group.subgroup?
            bad_request!(nil) unless ::Ability.allowed?(current_user, :admin_group_member, group)

            users = paginate(group.billed_users_for(params[:search], params[:sort]))

            present users, with: ::API::Entities::UserBasic, current_user: current_user
          end
        end
      end
    end
  end
end
