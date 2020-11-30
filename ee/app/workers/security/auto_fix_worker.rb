# frozen_string_literal: true

module Security
  class AutoFixWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    def perform(pipeline_id)
      return if Feature.disabled?(:security_auto_fix)

      ::Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
        project = pipeline.project

        break unless ProjectSecuritySetting.safe_find_or_create_for(project).auto_fix_enabled?

        Security::AutoFixService.new(project, pipeline).execute
      end
    end
  end
end
