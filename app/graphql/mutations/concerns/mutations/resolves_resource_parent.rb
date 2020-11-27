# frozen_string_literal: true

module Mutations
  module ResolvesResourceParent
    extend ActiveSupport::Concern
    include Mutations::ResolvesGroup
    include ResolvesProject

    included do
      argument :project_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The project full path the resource is associated with'

      argument :group_path, GraphQL::ID_TYPE,
               required: false,
               description: 'The group full path the resource is associated with'
    end

    def ready?(**args)
      unless args[:project_path].present? ^ args[:group_path].present?
        raise Gitlab::Graphql::Errors::ArgumentError,
              'Exactly one of group_path or project_path arguments is required'
      end

      super
    end

    private

    def authorized_resource_parent_find!(args)
      authorized_find!(project_path: args.delete(:project_path),
                       group_path: args.delete(:group_path))
    end

    def find_object(project_path: nil, group_path: nil)
      if group_path.present?
        resolve_group(full_path: group_path)
      else
        resolve_project(full_path: project_path)
      end
    end
  end
end
