# frozen_string_literal: true

module EE
  module API
    module Helpers
      module SettingsHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_params_ee do
            optional :elasticsearch_aws, type: Grape::API::Boolean, desc: 'Enable support for AWS hosted elasticsearch'

            given elasticsearch_aws: ->(val) { val } do
              optional :elasticsearch_aws_access_key, type: String, desc: 'AWS IAM access key'
              requires :elasticsearch_aws_region, type: String, desc: 'The AWS region the elasticsearch domain is configured'
              optional :elasticsearch_aws_secret_access_key, type: String, desc: 'AWS IAM secret access key'
            end

            optional :elasticsearch_indexing, type: Grape::API::Boolean, desc: 'Enable Elasticsearch indexing'

            given elasticsearch_indexing: ->(val) { val } do
              optional :elasticsearch_search, type: Grape::API::Boolean, desc: 'Enable Elasticsearch search'
              optional :elasticsearch_pause_indexing, type: Grape::API::Boolean, desc: 'Pause Elasticsearch indexing'
              requires :elasticsearch_url, type: String, desc: 'The url to use for connecting to Elasticsearch. Use a comma-separated list to support clustering (e.g., "http://localhost:9200, http://localhost:9201")'
              optional :elasticsearch_limit_indexing, type: Grape::API::Boolean, desc: 'Limit Elasticsearch to index certain namespaces and projects'
            end

            given elasticsearch_limit_indexing: ->(val) { val } do
              optional :elasticsearch_namespace_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The namespace ids to index with Elasticsearch.'
              optional :elasticsearch_project_ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: 'The project ids to index with Elasticsearch.'
            end

            optional :secret_detection_token_revocation_enabled, type: ::Grape::API::Boolean, desc: 'Enable Secret Detection Token Revocation'
            given secret_detection_token_revocation_enabled: ->(val) { val } do
              requires :secret_detection_token_revocation_url, type: String, desc: 'The configured Secret Detection Token Revocation instance URL'
              requires :secret_detection_revocation_token_types_url, type: String, desc: 'The configured Secret Detection Revocation Token Types instance URL'
            end

            optional :email_additional_text, type: String, desc: 'Additional text added to the bottom of every email for legal/auditing/compliance reasons'
            optional :default_project_deletion_protection, type: Grape::API::Boolean, desc: 'Disable project owners ability to delete project'
            optional :deletion_adjourned_period, type: Integer, desc: 'Number of days between marking project as deleted and actual removal'
            optional :help_text, type: String, desc: 'GitLab server administrator information'
            optional :repository_size_limit, type: Integer, desc: 'Size limit per repository (MB)'
            optional :file_template_project_id, type: Integer, desc: 'ID of project where instance-level file templates are stored.'
            optional :usage_ping_enabled, type: Grape::API::Boolean, desc: 'Every week GitLab will report license usage back to GitLab, Inc.'
            optional :updating_name_disabled_for_users, type: Grape::API::Boolean, desc: 'Flag indicating if users are permitted to update their profile name'
            optional :disable_overriding_approvers_per_merge_request, type: Grape::API::Boolean, desc: 'Disable Users ability to overwrite approvers in merge requests.'
            optional :prevent_merge_requests_author_approval, type: Grape::API::Boolean, desc: 'Disable Merge request author ability to approve request.'
            optional :prevent_merge_requests_committers_approval, type: Grape::API::Boolean, desc: 'Disable Merge request committer ability to approve request.'
            optional :npm_package_requests_forwarding, type: Grape::API::Boolean, desc: 'NPM package requests are forwarded to npmjs.org if not found on GitLab.'
            optional :group_owners_can_manage_default_branch_protection, type: Grape::API::Boolean, desc: 'Allow owners to manage default branch protection in groups'
            optional :maintenance_mode, type: Grape::API::Boolean, desc: 'When instance is in maintenance mode, non-admin users can sign in with read-only access and make read-only API requests'
            optional :maintenance_mode_message, type: String, desc: 'Message displayed when instance is in maintenance mode'
          end
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :optional_attributes
          def optional_attributes
            super + EE::ApplicationSettingsHelper.possible_licensed_attributes
          end
        end
      end
    end
  end
end
