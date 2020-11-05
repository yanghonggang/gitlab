# frozen_string_literal: true

module EE
  module API
    module Projects
      extend ActiveSupport::Concern

      prepended do
        resource :projects do
          desc 'Restore a project' do
            success Entities::Project
          end
          post ':id/restore', feature_category: :authentication_and_authorization do
            authorize!(:remove_project, user_project)
            break not_found! unless user_project.feature_available?(:adjourned_deletion_for_projects_and_groups)

            result = ::Projects::RestoreService.new(user_project, current_user).execute
            if result[:status] == :success
              present user_project, with: ::API::Entities::Project, current_user: current_user
            else
              render_api_error!(result[:message], 400)
            end
          end
          segment ':id/audit_events', feature_category: :audit_events do
            before do
              authorize! :admin_project, user_project
              check_audit_events_available!(user_project)
              increment_unique_values('a_compliance_audit_events_api', current_user.id)
            end

            desc 'Get a list of audit events in this project.' do
              success EE::API::Entities::AuditEvent
            end
            params do
              optional :created_after, type: DateTime, desc: 'Return audit events created after the specified time'
              optional :created_before, type: DateTime, desc: 'Return audit events created before the specified time'

              use :pagination
            end
            get '/', feature_category: :audit_events do
              level = ::Gitlab::Audit::Levels::Project.new(project: user_project)
              audit_events = AuditLogFinder.new(
                level: level,
                params: audit_log_finder_params
              ).execute

              present paginate(audit_events), with: EE::API::Entities::AuditEvent
            end

            desc 'Get a specific audit event in this project.' do
              success EE::API::Entities::AuditEvent
            end
            params do
              requires :audit_event_id, type: Integer, desc: 'The ID of the audit event'
            end
            get '/:audit_event_id', feature_category: :audit_events do
              level = ::Gitlab::Audit::Levels::Project.new(project: user_project)
              # rubocop: disable CodeReuse/ActiveRecord
              # This is not `find_by!` from ActiveRecord
              audit_event = AuditLogFinder.new(level: level, params: audit_log_finder_params)
                .find_by!(id: params[:audit_event_id])
              # rubocop: enable CodeReuse/ActiveRecord

              present audit_event, with: EE::API::Entities::AuditEvent
            end
          end
        end

        helpers do
          extend ::Gitlab::Utils::Override

          def apply_filters(projects)
            projects = super(projects)
            projects = projects.verification_failed_wikis if params[:wiki_checksum_failed]
            projects = projects.verification_failed_repos if params[:repository_checksum_failed]

            projects
          end

          override :verify_update_project_attrs!
          def verify_update_project_attrs!(project, attrs)
            super

            verify_mirror_attrs!(project, attrs)
          end

          def verify_mirror_attrs!(project, attrs)
            unless can?(current_user, :admin_mirror, project)
              ::Projects::UpdateService::PULL_MIRROR_ATTRIBUTES.each do |attr_name|
                attrs.delete(attr_name)
              end
            end
          end

          def check_audit_events_available!(project)
            forbidden! unless project.feature_available?(:audit_events)
          end

          def audit_log_finder_params
            params.slice(:created_after, :created_before)
          end

          override :delete_project
          def delete_project(user_project)
            return super unless user_project.adjourned_deletion?

            result = destroy_conditionally!(user_project) do
              ::Projects::MarkForDeletionService.new(user_project, current_user, {}).execute
            end

            if result[:status] == :success
              accepted!
            else
              render_api_error!(result[:message], 400)
            end
          end
        end
      end
    end
  end
end
