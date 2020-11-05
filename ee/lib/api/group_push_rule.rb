# frozen_string_literal: true

module API
  class GroupPushRule < ::API::Base
    feature_category :source_code_management

    before { authenticate! }
    before { check_group_push_rule_access! }
    before { authorize_change_param(user_group, :commit_committer_check, :reject_unsigned_commits) }

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end

    resource :groups do
      helpers do
        def check_group_push_rule_access!
          not_found! unless can?(current_user, :change_push_rules, user_group)
        end

        params :push_rule_params do
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag'
          optional :member_check, type: Boolean, desc: 'Restrict commits by author (email) to existing GitLab users'
          optional :prevent_secrets, type: Boolean, desc: 'GitLab will reject any files that are likely to contain secrets'
          optional :commit_message_regex, type: String, desc: 'All commit messages must match this'
          optional :commit_message_negative_regex, type: String, desc: 'No commit message is allowed to match this'
          optional :branch_name_regex, type: String, desc: 'All branches names must match this'
          optional :author_email_regex, type: String, desc: 'All commit author emails must match this'
          optional :file_name_regex, type: String, desc: 'All committed filenames must not match this'
          optional :max_file_size, type: Integer, desc: 'Maximum file size (MB)'
          optional :commit_committer_check, type: Boolean, desc: 'Users may only push their own commits'
          optional :reject_unsigned_commits, type: Boolean, desc: 'Only GPG signed commits can be pushed to this repository'
          at_least_one_of :deny_delete_tag, :member_check, :prevent_secrets,
                          :commit_message_regex, :commit_message_negative_regex, :branch_name_regex,
                          :author_email_regex,
                          :file_name_regex, :max_file_size,
                          :commit_committer_check,
                          :reject_unsigned_commits
        end
      end

      desc 'Get group push rule' do
        detail 'This feature was introduced in GitLab 13.4.'
        success EE::API::Entities::GroupPushRule
      end
      get ":id/push_rule" do
        push_rule = user_group.push_rule

        not_found! unless push_rule

        present push_rule, with: EE::API::Entities::GroupPushRule, user: current_user
      end

      desc 'Add a push rule to a group' do
        detail 'This feature was introduced in GitLab 13.4.'
        success EE::API::Entities::GroupPushRule
      end
      params do
        use :push_rule_params
      end
      post ":id/push_rule" do
        render_api_error!(_('Group push rule exists, try updating'), 422) if user_group.push_rule

        allowed_params = declared_params(include_missing: false)
        user_group.update!(push_rule: PushRule.create!(allowed_params))
        present user_group.push_rule, with: EE::API::Entities::GroupPushRule, user: current_user
      end

      desc 'Edit push rule of a group' do
        detail 'This feature was introduced in GitLab 13.4.'
        success EE::API::Entities::GroupPushRule
      end
      params do
        use :push_rule_params
      end
      put ":id/push_rule" do
        push_rule = user_group.push_rule
        not_found! unless push_rule

        if push_rule.update(declared_params(include_missing: false))
          present push_rule, with: EE::API::Entities::GroupPushRule, user: current_user
        else
          render_validation_error!(push_rule)
        end
      end

      desc 'Deletes group push rule' do
        detail 'This feature was introduced in GitLab 13.4.'
      end
      delete ":id/push_rule" do
        push_rule = user_group.push_rule
        not_found! unless push_rule

        destroy_conditionally!(push_rule)
      end
    end
  end
end
