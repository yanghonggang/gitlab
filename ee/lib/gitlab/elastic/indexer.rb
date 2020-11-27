# frozen_string_literal: true

# Create a separate process, which does not load the Rails environment, to index
# each repository. This prevents memory leaks in the indexer from affecting the
# rest of the application.
module Gitlab
  module Elastic
    class Indexer
      include Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      class << self
        def indexer_version
          Rails.root.join('GITLAB_ELASTICSEARCH_INDEXER_VERSION').read.chomp
        end
      end

      attr_reader :project, :index_status, :wiki
      alias_method :index_wiki?, :wiki

      def initialize(project, wiki: false)
        @project = project
        @wiki = wiki

        # Use the eager-loaded association if available.
        @index_status = project.index_status
      end

      # Runs the indexation process, which is the following:
      # - Purge the index for any unreachable commits;
      # - Run the `gitlab-elasticsearch-indexer`;
      # - Update the `index_status` for the associated project;
      #
      # ref - Git ref up to which the indexation will run (default: HEAD)
      def run(ref = 'HEAD')
        commit = find_indexable_commit(ref)
        return update_index_status(Gitlab::Git::BLANK_SHA) unless commit

        repository.__elasticsearch__.elastic_writing_targets.each do |target|
          Sidekiq.logger.debug(message: "Indexation running for #{project.id} #{from_sha}..#{commit.sha}",
                               project_id: project.id,
                               wiki: index_wiki?)
          run_indexer!(commit.sha, target)
        end

        # update the index status only if all writes were successful
        update_index_status(commit.sha)

        true
      end

      def find_indexable_commit(ref)
        !repository.empty? && repository.commit(ref)
      end

      private

      def repository
        index_wiki? ? project.wiki.repository : project.repository
      end

      def run_indexer!(to_sha, target)
        # This might happen when default branch has been reset or rebased.
        base_sha = if purge_unreachable_commits_from_index!(to_sha, target)
                     Gitlab::Git::EMPTY_TREE_ID
                   else
                     from_sha
                   end

        vars = build_envvars(base_sha, to_sha, target)
        path_to_indexer = Gitlab.config.elasticsearch.indexer_path

        command =
          if index_wiki?
            [path_to_indexer, "--blob-type=wiki_blob", "--skip-commits", "--project-path=#{project.full_path}", project.id.to_s, repository_path]
          else
            [path_to_indexer, "--project-path=#{project.full_path}", project.id.to_s, repository_path]
          end

        output, status = Gitlab::Popen.popen(command, nil, vars)

        raise Error, output unless status&.zero?
      end

      # Remove all indexed data for commits and blobs for a project.
      #
      # @return: whether the index has been purged
      def purge_unreachable_commits_from_index!(to_sha, target)
        return false if last_commit_ancestor_of?(to_sha)

        target.delete_index_for_commits_and_blobs(wiki: index_wiki?)
        true
      rescue ::Elasticsearch::Transport::Transport::Errors::BadRequest => e
        Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
      end

      def build_envvars(from_sha, to_sha, target)
        # We accept any form of settings, including string and array
        # This is why JSON is needed
        vars = {
          'RAILS_ENV'               => Rails.env,
          'ELASTIC_CONNECTION_INFO' => elasticsearch_config(target),
          'GITALY_CONNECTION_INFO'  => gitaly_config,
          'FROM_SHA'                => from_sha,
          'TO_SHA'                  => to_sha,
          'CORRELATION_ID'          => Labkit::Correlation::CorrelationId.current_id,
          'SSL_CERT_FILE'           => OpenSSL::X509::DEFAULT_CERT_FILE,
          'SSL_CERT_DIR'            => OpenSSL::X509::DEFAULT_CERT_DIR
        }

        # Set AWS environment variables for IAM role authentication if present
        if Gitlab::CurrentSettings.elasticsearch_config[:aws]
          vars = build_aws_credentials_env(vars)
        end

        # Users can override default SSL certificate path via SSL_CERT_FILE SSL_CERT_DIR
        vars.merge(ENV.slice('SSL_CERT_FILE', 'SSL_CERT_DIR'))
      end

      def build_aws_credentials_env(vars)
        # AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN need to be set as
        # environment variable in case of using IAM role based authentication in AWS
        # The credentials are buffered to prevent from hitting rate limit. They will be
        # refreshed when expired
        credentials = Gitlab::Elastic::Client.aws_credential_provider&.credentials
        return vars unless credentials&.set?

        vars.merge(
          'AWS_ACCESS_KEY_ID' => credentials.access_key_id,
          'AWS_SECRET_ACCESS_KEY' => credentials.secret_access_key,
          'AWS_SESSION_TOKEN' => credentials.session_token
        )
      end

      def last_commit
        index_wiki? ? index_status&.last_wiki_commit : index_status&.last_commit
      end

      def from_sha
        strong_memoize(:from_sha) do
          repository_contains_last_indexed_commit? ? last_commit : Gitlab::Git::EMPTY_TREE_ID
        end
      end

      def repository_contains_last_indexed_commit?
        strong_memoize(:repository_contains_last_indexed_commit) do
          last_commit.present? && repository.commit(last_commit).present?
        end
      end

      def last_commit_ancestor_of?(to_sha)
        return true if from_sha == Gitlab::Git::BLANK_SHA
        return false unless repository_contains_last_indexed_commit?

        # we always treat the `EMPTY_TREE_ID` as an ancestor to make sure
        # we don't try to purge an empty index
        from_sha == Gitlab::Git::EMPTY_TREE_ID || repository.ancestor?(from_sha, to_sha)
      end

      def repository_path
        "#{repository.disk_path}.git"
      end

      def elasticsearch_config(target)
        Gitlab::CurrentSettings.elasticsearch_config.merge(
          index_name: target.index_name
        ).to_json
      end

      def gitaly_config
        {
          storage: project.repository_storage,
          limit_file_size: Gitlab::CurrentSettings.elasticsearch_indexed_file_size_limit_kb.kilobytes
        }.merge(Gitlab::GitalyClient.connection_data(project.repository_storage)).to_json
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def update_index_status(to_sha)
        unless Project.exists?(id: project.id)
          Gitlab::Elasticsearch::Logger.build.debug(
            message: 'Index status could not be updated as the project does not exist',
            project_id: project.id,
            wiki: index_wiki?
          )
          return false
        end

        raise "Invalid sha #{to_sha}" unless to_sha.present?

        # An index_status should always be created,
        # even if the repository is empty, so we know it's been looked at.
        @index_status ||= IndexStatus.safe_find_or_create_by!(project_id: project.id)

        attributes =
          if index_wiki?
            { last_wiki_commit: to_sha, wiki_indexed_at: Time.now }
          else
            { last_commit: to_sha, indexed_at: Time.now }
          end

        @index_status.update!(attributes)

        project.reload_index_status
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
