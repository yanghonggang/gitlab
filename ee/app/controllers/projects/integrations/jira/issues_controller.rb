# frozen_string_literal: true

module Projects
  module Integrations
    module Jira
      class IssuesController < Projects::ApplicationController
        include RecordUserLastActivity
        include SortingHelper
        include SortingPreference

        before_action :check_feature_enabled!

        before_action do
          push_frontend_feature_flag(:jira_issues_integration, project, type: :licensed, default_enabled: true)
          push_frontend_feature_flag(:jira_issues_list, project, type: :development)
        end

        rescue_from ::Projects::Integrations::Jira::IssuesFinder::IntegrationError, with: :render_integration_error
        rescue_from ::Projects::Integrations::Jira::IssuesFinder::RequestError, with: :render_request_error

        feature_category :integrations

        def index
          params[:state] = params[:state].presence || default_state

          respond_to do |format|
            format.html
            format.json do
              render json: issues_json
            end
          end
        end

        private

        def issues_json
          jira_issues = finder.execute
          jira_issues = Kaminari.paginate_array(jira_issues, limit: finder.per_page, total_count: finder.total_count)

          ::Integrations::Jira::IssueSerializer.new
            .with_pagination(request, response)
            .represent(jira_issues, project: project)
        end

        def finder
          @finder ||= finder_type.new(project, finder_options)
        end

        def finder_type
          ::Projects::Integrations::Jira::IssuesFinder
        end

        def finder_options
          options = { sort: set_sort_order }

          # Used by view to highlight active option
          @sort = options[:sort]

          params.permit(finder_type.valid_params).merge(options)
        end

        def default_state
          'opened'
        end

        def default_sort_order
          case params[:state]
          when 'opened', 'all' then sort_value_created_date
          when 'closed'        then sort_value_recently_updated
          else sort_value_created_date
          end
        end

        protected

        def check_feature_enabled!
          return render_404 unless project.jira_issues_integration_available? && project.external_issue_tracker
        end

        # Return the informational message to the user
        def render_integration_error(exception)
          render json: { errors: [exception.message] }, status: :bad_request
        end

        # Log the specific request error details and return generic message
        def render_request_error(exception)
          Gitlab::AppLogger.error(exception)

          render json: { errors: [_('An error occurred while requesting data from the Jira service')] }, status: :bad_request
        end
      end
    end
  end
end
