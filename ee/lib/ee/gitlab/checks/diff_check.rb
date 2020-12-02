# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module DiffCheck
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        def path_validations
          validations = [super].flatten

          if validate_code_owners?
            validations << validate_code_owners
          end

          validations
        end

        def validate_code_owners?
          return false if updated_from_web?
          return false if ::Feature.enabled?(:push_rules_supersede_code_owners, project, default_enabled: true) && user_access.can_push_to_branch?(branch_name)

          project.branch_requires_code_owner_approval?(branch_name)
        end

        def validate_code_owners
          lambda do |paths|
            validator = ::Gitlab::CodeOwners::Validator.new(project, branch_name, paths)

            validator.execute
          end
        end

        def validate_path_locks?
          strong_memoize(:validate_path_locks) do
            project.feature_available?(:file_locks) &&
              project.any_path_locks? &&
              project.default_branch == branch_name # locks protect default branch only
          end
        end

        def push_rule_checks_commit?
          return false unless push_rule

          push_rule.file_name_regex.present? || push_rule.prevent_secrets
        end

        override :validations_for_diff
        def validations_for_diff
          super.tap do |validations|
            validations.push(path_locks_validation) if validate_path_locks?
            validations.push(file_name_validation) if push_rule_checks_commit?
          end
        end

        def path_locks_validation
          lambda do |diff|
            path = if ::Feature.enabled?(:diff_check_with_paths_changed_rpc, project)
                     diff.path
                   else
                     if diff.renamed_file?
                       diff.old_path
                     else
                       diff.new_path || diff.old_path
                     end
                   end

            lock_info = project.find_path_lock(path)

            if lock_info && lock_info.user != user_access.user
              return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
            end
          end
        end

        def new_file?(path)
          path.status == :ADDED
        end

        def file_name_validation
          lambda do |diff|
            if ::Feature.enabled?(:diff_check_with_paths_changed_rpc, project)
              if new_file?(diff) && denylisted_regex = push_rule.filename_denylisted?(diff.path)
                return unless denylisted_regex.present?

                "File name #{diff.path} was blacklisted by the pattern #{denylisted_regex}."
              end
            else
              if (diff.renamed_file || diff.new_file) && denylisted_regex = push_rule.filename_denylisted?(diff.new_path)
                return unless denylisted_regex.present?

                "File name #{diff.new_path} was blacklisted by the pattern #{denylisted_regex}."
              end
            end
          rescue ::PushRule::MatchError => e
            raise ::Gitlab::GitAccess::ForbiddenError, e.message
          end
        end
      end
    end
  end
end
