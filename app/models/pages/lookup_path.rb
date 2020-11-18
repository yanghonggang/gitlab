# frozen_string_literal: true

module Pages
  class LookupPath
    def initialize(project, trim_prefix: nil, domain: nil)
      @project = project
      @domain = domain
      @trim_prefix = trim_prefix || project.full_path
    end

    def project_id
      project.id
    end

    def access_control
      project.private_pages?
    end

    def https_only
      domain_https = domain ? domain.https? : true
      project.pages_https_only? && domain_https
    end

    def source
      zip_source || file_source
    end

    def prefix
      if project.pages_group_root?
        '/'
      else
        project.full_path.delete_prefix(trim_prefix) + '/'
      end
    end

    private

    attr_reader :project, :trim_prefix, :domain

    def artifacts_archive
      return unless Feature.enabled?(:pages_serve_from_artifacts_archive, project)

      project.pages_metadatum.artifacts_archive
    end

    def deployment
      return unless Feature.enabled?(:pages_serve_from_deployments, project)

      project.pages_metadatum.pages_deployment
    end

    def zip_source
      source = deployment || artifacts_archive

      return unless source&.file

      return if source.file.file_storage? && !Feature.enabled?(:pages_serve_with_zip_file_protocol, project)

      # artifacts archive doesn't support this
      file_count = source.file_count if source.respond_to?(:file_count)

      global_id = ::Gitlab::GlobalId.build(source, id: source.id).to_s

      {
        type: 'zip',
        path: source.file.url_or_file_path(expire_at: 1.day.from_now),
        global_id: global_id,
        sha256: source.file_sha256,
        file_size: source.size,
        file_count: file_count
      }
    end

    def file_source
      {
        type: 'file',
        path: File.join(project.full_path, 'public/')
      }
    end
  end
end
