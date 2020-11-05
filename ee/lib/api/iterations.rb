# frozen_string_literal: true

module API
  class Iterations < ::API::Base
    include PaginationParams

    feature_category :issue_tracking

    helpers do
      params :list_params do
        optional :state, type: String, values: %w[opened upcoming started closed all], default: 'all',
                 desc: 'Return "opened", "upcoming", "started", "closed", or "all" milestones'
        optional :search, type: String, desc: 'The search criteria for the title of the iteration'
        optional :include_ancestors, type: Grape::API::Boolean, default: true,
                 desc: 'Include iterations from parent and its ancestors'
        use :pagination
      end

      def list_iterations_for(parent)
        iterations = IterationsFinder.new(current_user, iterations_finder_params(parent)).execute

        present paginate(iterations), with: EE::API::Entities::Iteration
      end

      def iterations_finder_params(parent)
        IterationsFinder.params_for_parent(parent, include_ancestors: params[:include_ancestors]).merge!(
          state: params[:state],
          search_title: params[:search]
        )
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project iterations' do
        detail 'This feature was introduced in GitLab 13.5'
        success EE::API::Entities::Iteration
      end
      params do
        use :list_params
      end
      get ":id/iterations" do
        authorize! :read_iteration, user_project

        list_iterations_for(user_project)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a group'
    end
    resource :groups, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of group iterations' do
        detail 'This feature was introduced in GitLab 13.5'
        success EE::API::Entities::Iteration
      end
      params do
        use :list_params
      end
      get ":id/iterations" do
        authorize! :read_iteration, user_group

        list_iterations_for(user_group)
      end
    end
  end
end
