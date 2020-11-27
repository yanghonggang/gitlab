# frozen_string_literal: true

module Mutations
  module ContainerRepositories
    class DestroyTags < ::Mutations::ContainerRepositories::DestroyBase
      LIMIT = 20.freeze

      TOO_MANY_TAGS_ERROR_MESSAGE = "Tag names size is bigger than #{LIMIT}"

      graphql_name 'DestroyContainerRepositoryTags'

      authorize :destroy_container_image

      argument :id,
               ::Types::GlobalIDType[::ContainerRepository],
               required: true,
               description: 'ID of the container repository.'

      argument :tag_names,
               [String],
               required: true,
               description: "Container repository tag names to delete. Can't be bigger than #{LIMIT}",
               prepare: ->(tag_names, ctx) do
                 raise Gitlab::Graphql::Errors::ArgumentError, TOO_MANY_TAGS_ERROR_MESSAGE if tag_names.size > LIMIT

                 tag_names
               end

      field :deleted_tag_names,
            [String],
            description: 'Deleted container repository tag names',
            null: false

      def resolve(id:, tag_names:)
        container_repository = authorized_find!(id: id)

        result = ::Projects::ContainerRepository::DeleteTagsService
          .new(container_repository.project, current_user, tags: tag_names)
          .execute(container_repository)

        track_event(:delete_tag_bulk, :tag)

        {
          errors: [result[:message]].compact,
          deleted_tag_names: result[:deleted]
        }
      end
    end
  end
end
