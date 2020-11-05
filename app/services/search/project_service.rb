# frozen_string_literal: true

module Search
  class ProjectService
    include Gitlab::Utils::StrongMemoize

    ALLOWED_SCOPES = %w(notes issues merge_requests milestones wiki_blobs commits users).freeze

    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      Gitlab::ProjectSearchResults.new(current_user,
                                       params[:search],
                                       project: project,
                                       repository_ref: params[:repository_ref],
                                       order_by: params[:order_by],
                                       sort: params[:sort],
                                       filters: { confidential: params[:confidential], state: params[:state] }
                                      )
    end

    def allowed_scopes
      ALLOWED_SCOPES
    end

    def scope
      strong_memoize(:scope) do
        allowed_scopes.include?(params[:scope]) ? params[:scope] : 'blobs'
      end
    end
  end
end

Search::ProjectService.prepend_if_ee('EE::Search::ProjectService')
