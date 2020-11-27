# frozen_string_literal: true

module RequirementsManagement
  class ImportRequirementsCsvWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    idempotent!
    feature_category :requirements_management
    # TODO: Set worker_resource_boundary.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/281173

    sidekiq_retries_exhausted do |job|
      Upload.find(job['args'][2]).destroy
    end

    def perform(current_user_id, project_id, upload_id)
      upload = Upload.find(upload_id)
      user = User.find(current_user_id)
      project = Project.find(project_id)

      RequirementsManagement::ImportCsvService.new(user, project, upload.retrieve_uploader).execute
      upload.destroy!
    rescue ActiveRecord::RecordNotFound
      # Resources have been removed, job should not be retried
    end
  end
end
