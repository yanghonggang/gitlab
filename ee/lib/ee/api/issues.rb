# frozen_string_literal: true

module EE
  module API
    module Issues
      extend ActiveSupport::Concern

      prepended do
        params do
          requires :id, type: String, desc: 'The ID of a project'
        end

        resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
          namespace ':id/issues/:issue_iid/metric_images' do
            post 'authorize' do
              authorize!(:upload_issuable_metric_image, find_project_issue(request.params[:issue_iid]))

              require_gitlab_workhorse!
              ::Gitlab::Workhorse.verify_api_request!(request.headers)
              status 200
              content_type ::Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE

              params = {
                has_length: false,
                maximum_size: ::IssuableMetricImage::MAX_FILE_SIZE.to_i
              }

              ::IssuableMetricImageUploader.workhorse_authorize(**params)
            end

            desc 'Upload a metric image for an issue' do
              success Entities::IssuableMetricImage
            end
            params do
              requires :file, type: ::API::Validations::Types::WorkhorseFile, desc: 'The image file to be uploaded'
              optional :url, type: String, desc: 'The url to view more metric info'
            end
            post do
              require_gitlab_workhorse!
              bad_request!('File is too large') if max_file_size_exceeded?

              issue = find_project_issue(params[:issue_iid])

              upload = ::IncidentManagement::Incidents::UploadMetricService.new(
                issue,
                current_user,
                params.slice(:file, :url)
              ).execute

              if upload.success?
                present upload.payload[:metric], with: Entities::IssuableMetricImage, current_user: current_user, project: user_project
              else
                render_api_error!(upload.message, 403)
              end
            end

            desc 'Metric Images for issue'
            get do
              issue = find_project_issue(params[:issue_iid])

              if can?(current_user, :read_issuable_metric_image, issue)
                issue = ::IssuesFinder.new(
                  current_user,
                  project_id: user_project.id,
                  iids: [params[:issue_iid]]
                ).execute.first

                present issue.metric_images, with: Entities::IssuableMetricImage
              else
                render_api_error!('Issue not found', 404)
              end
            end
          end
        end

        helpers do
          include ::API::Helpers::Packages::BasicAuthHelpers

          def project
            authorized_user_project
          end

          def max_file_size_exceeded?
            params[:file].size > ::IssuableMetricImage::MAX_FILE_SIZE
          end
        end
      end
    end
  end
end
