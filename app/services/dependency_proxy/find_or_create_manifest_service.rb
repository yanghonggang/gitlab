# frozen_string_literal: true

module DependencyProxy
  class FindOrCreateManifestService < DependencyProxy::BaseService
    def initialize(group, image, tag, token)
      @group = group
      @image = image
      @tag = tag
      @token = token
      @file_name = "#{@image}:#{@tag}.json"
      @manifest = nil
    end

    def execute
      head_result = DependencyProxy::HeadManifestService.new(@image, @tag, @token).execute

      @manifest = @group.dependency_proxy_manifests.find_by_digest(head_result[:digest])

      return success(manifest: @manifest) if @manifest

      @manifest = pull_new_manifest
      respond
    rescue Timeout::Error, *Gitlab::HTTP::HTTP_ERRORS
      @manifest = @group.dependency_proxy_manifests.find_by_file_name(@file_name)
      respond
    end

    private

    def pull_new_manifest
      @manifest = DependencyProxy::PullManifestService.new(@image, @tag, @token).execute

      @group.dependency_proxy_manifests.create!(
        file_name: @file_name,
        digest: @manifest[:digest],
        file: @manifest[:file],
        size: @manifest[:file].size
      )
    end

    def respond
      if @manifest
        success(manifest: @manifest)
      else
        error('Failed to download the manifest', @manifest[:http_status])
      end
    end
  end
end
