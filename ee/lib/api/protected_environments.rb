# frozen_string_literal: true

module API
  class ProtectedEnvironments < ::API::Base
    include PaginationParams

    ENVIRONMENT_ENDPOINT_REQUIREMENTS = API::NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(name: API::NO_SLASH_URL_PART_REGEX)

    before { authorize_admin_project }

    feature_category :continuous_delivery

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc "Get a project's protected environments" do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        use :pagination
      end
      get ':id/protected_environments' do
        protected_environments = user_project.protected_environments.sorted_by_name

        present paginate(protected_environments), with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Get a single protected environment' do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      get ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
      end

      desc 'Protect a single environment' do
        detail 'This feature was introduced in GitLab 12.8.'
        success ::EE::API::Entities::ProtectedEnvironment
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'

        requires :deploy_access_levels, type: Array, desc: 'An array of users/groups allowed to deploy environment' do
          optional :access_level, type: Integer, values: ::ProtectedEnvironment::DeployAccessLevel::ALLOWED_ACCESS_LEVELS
          optional :user_id, type: Integer
          optional :group_id, type: Integer
        end
      end
      post ':id/protected_environments' do
        protected_environment = user_project.protected_environments.find_by_name(params[:name])

        if protected_environment
          conflict!("Protected environment '#{params[:name]}' already exists")
        end

        declared_params = declared_params(include_missing: false)
        # TODO: replace with `as: :deploy_access_levels_attributes` after the Grape update:
        # https://gitlab.com/gitlab-org/gitlab/issues/195960
        # original issue - https://github.com/ruby-grape/grape/issues/1874
        declared_params[:deploy_access_levels_attributes] = declared_params.delete(:deploy_access_levels)
        protected_environment = ::ProtectedEnvironments::CreateService
                                  .new(user_project, current_user, declared_params).execute

        if protected_environment.persisted?
          present protected_environment, with: ::EE::API::Entities::ProtectedEnvironment, project: user_project
        else
          render_api_error!(protected_environment.errors.full_messages, 422)
        end
      end

      desc 'Unprotect a single environment' do
        detail 'This feature was introduced in GitLab 12.8.'
      end
      params do
        requires :name, type: String, desc: 'The name of the protected environment'
      end
      delete ':id/protected_environments/:name', requirements: ENVIRONMENT_ENDPOINT_REQUIREMENTS do
        destroy_conditionally!(protected_environment) do
          ::ProtectedEnvironments::DestroyService.new(user_project, current_user).execute(protected_environment)
        end
      end
    end

    helpers do
      def protected_environment
        @protected_environment ||= user_project.protected_environments.find_by_name!(params[:name])
      end
    end
  end
end
