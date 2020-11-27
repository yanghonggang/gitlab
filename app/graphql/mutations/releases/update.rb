# frozen_string_literal: true

module Mutations
  module Releases
    class Update < Base
      graphql_name 'ReleaseUpdate'

      field :release,
            Types::ReleaseType,
            null: true,
            description: 'The release after mutation.'

      argument :tag_name, GraphQL::STRING_TYPE,
               required: true, as: :tag,
               description: 'Name of the tag associated with the release'

      argument :name, GraphQL::STRING_TYPE,
               required: false,
               description: 'Name of the release'

      argument :description, GraphQL::STRING_TYPE,
               required: false,
               description: 'Description (release notes) of the release'

      argument :released_at, Types::TimeType,
               required: false,
               description: 'The release date'

      argument :milestones, [GraphQL::STRING_TYPE],
               required: false,
               description: 'The title of each milestone the release is associated with. GitLab Premium customers can specify group milestones.'

      authorize :update_release

      def ready?(**args)
        if args.key?(:released_at) && args[:released_at].nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'if the releasedAt argument is provided, it cannot be null'
        end

        if args.key?(:milestones) && args[:milestones].nil?
          raise Gitlab::Graphql::Errors::ArgumentError,
                'if the milestones argument is provided, it cannot be null'
        end

        super
      end

      def resolve(project_path:, **scalars)
        project = authorized_find!(full_path: project_path)

        params = scalars.with_indifferent_access

        release_result = ::Releases::UpdateService.new(project, current_user, params).execute

        if release_result[:status] == :success
          {
            release: release_result[:release],
            errors: []
          }
        else
          {
            release: nil,
            errors: [release_result[:message]]
          }
        end
      end
    end
  end
end
