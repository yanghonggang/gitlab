---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Prometheus metrics

To enable the GitLab Prometheus metrics:

1. Log into GitLab as a user with [administrator permissions](../../../user/permissions.md).
1. Navigate to **Admin Area > Settings > Metrics and profiling**.
1. Find the **Metrics - Prometheus** section, and click **Enable Prometheus Metrics**.
1. [Restart GitLab](../../restart_gitlab.md#omnibus-gitlab-restart) for the changes to take effect.

For installations from source you must configure it yourself.

## Collecting the metrics

GitLab monitors its own internal service metrics, and makes them available at the
`/-/metrics` endpoint. Unlike other [Prometheus](https://prometheus.io) exporters, to access
the metrics, the client IP address must be [explicitly allowed](../ip_whitelist.md).

For [Omnibus GitLab](https://docs.gitlab.com/omnibus/) and Chart installations,
these metrics are enabled and collected as of
[GitLab 9.4](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/1702).
For source installations, these metrics must be enabled
manually and collected by a Prometheus server.

For enabling and viewing metrics from Sidekiq nodes, see [Sidekiq metrics](#sidekiq-metrics).

## Metrics available

The following metrics are available:

| Metric                                                         | Type      |                  Since | Description                                                                                         | Labels                                              |
|:---------------------------------------------------------------|:----------|-----------------------:|:----------------------------------------------------------------------------------------------------|:----------------------------------------------------|
| `gitlab_banzai_cached_render_real_duration_seconds`            | Histogram |                    9.4 | Duration of rendering Markdown into HTML when cached output exists                                  | `controller`, `action`                              |
| `gitlab_banzai_cacheless_render_real_duration_seconds`         | Histogram |                    9.4 | Duration of rendering Markdown into HTML when cached output does not exist                          | `controller`, `action`                              |
| `gitlab_cache_misses_total`                                    | Counter   |                   10.2 | Cache read miss                                                                                     | `controller`, `action`                              |
| `gitlab_cache_operation_duration_seconds`                      | Histogram |                   10.2 | Cache access time                                                                                   |                                                     |
| `gitlab_cache_operations_total`                                | Counter   |                   12.2 | Cache operations by controller or action                                                               | `controller`, `action`, `operation`                 |
| `gitlab_ci_pipeline_creation_duration_seconds`                 | Histogram |                   13.0 | Time in seconds it takes to create a CI/CD pipeline                                                 |                                                     |
| `gitlab_ci_pipeline_size_builds`                               | Histogram |                   13.1 | Total number of builds within a pipeline grouped by a pipeline source                               | `source`                                            |
| `job_waiter_started_total`                                     | Counter   |                   12.9 | Number of batches of jobs started where a web request is waiting for the jobs to complete           | `worker`                                            |
| `job_waiter_timeouts_total`                                    | Counter   |                   12.9 | Number of batches of jobs that timed out where a web request is waiting for the jobs to complete    | `worker`                                            |
| `gitlab_database_transaction_seconds`                          | Histogram |                   12.1 | Time spent in database transactions, in seconds                                                     |                                                     |
| `gitlab_method_call_duration_seconds`                          | Histogram |                   10.2 | Method calls real duration                                                                          | `controller`, `action`, `module`, `method`          |
| `gitlab_page_out_of_bounds`                                    | Counter   |                   12.8 | Counter for the PageLimiter pagination limit being hit                                              | `controller`, `action`, `bot`                       |
| `gitlab_rails_queue_duration_seconds`                          | Histogram |                    9.4 | Measures latency between GitLab Workhorse forwarding a request to Rails                             |                                                     |
| `gitlab_sql_duration_seconds`                                  | Histogram |                   10.2 | SQL execution time, excluding `SCHEMA` operations and `BEGIN` / `COMMIT`                                  |                                                     |
| `gitlab_ruby_threads_max_expected_threads`                     | Gauge |                       13.3 | Maximum number of threads expected to be running and performing application work                    |
| `gitlab_ruby_threads_running_threads`                          | Gauge |                       13.3 | Number of running Ruby threads by name                    |
| `gitlab_transaction_cache_<key>_count_total`                   | Counter   |                   10.2 | Counter for total Rails cache calls (per key)                                                       |                                                     |
| `gitlab_transaction_cache_<key>_duration_total`                | Counter   |                   10.2 | Counter for total time (seconds) spent in Rails cache calls (per key)                               |                                                     |
| `gitlab_transaction_cache_count_total`                         | Counter   |                   10.2 | Counter for total Rails cache calls (aggregate)                                                     |                                                     |
| `gitlab_transaction_cache_duration_total`                      | Counter   |                   10.2 | Counter for total time (seconds) spent in Rails cache calls (aggregate)                             |                                                     |
| `gitlab_transaction_cache_read_hit_count_total`                | Counter   |                   10.2 | Counter for cache hits for Rails cache calls                                                        | `controller`, `action`                              |
| `gitlab_transaction_cache_read_miss_count_total`               | Counter   |                   10.2 | Counter for cache misses for Rails cache calls                                                      | `controller`, `action`                              |
| `gitlab_transaction_duration_seconds`                          | Histogram |                   10.2 | Duration for all transactions (`gitlab_transaction_*` metrics)                                        | `controller`, `action`                              |
| `gitlab_transaction_event_build_found_total`                   | Counter   |                    9.4 | Counter for build found for API /jobs/request                                                       |                                                     |
| `gitlab_transaction_event_build_invalid_total`                 | Counter   |                    9.4 | Counter for build invalid due to concurrency conflict for API /jobs/request                         |                                                     |
| `gitlab_transaction_event_build_not_found_cached_total`        | Counter   |                    9.4 | Counter for cached response of build not found for API /jobs/request                                |                                                     |
| `gitlab_transaction_event_build_not_found_total`               | Counter   |                    9.4 | Counter for build not found for API /jobs/request                                                   |                                                     |
| `gitlab_transaction_event_change_default_branch_total`         | Counter   |                    9.4 | Counter when default branch is changed for any repository                                           |                                                     |
| `gitlab_transaction_event_create_repository_total`             | Counter   |                    9.4 | Counter when any repository is created                                                              |                                                     |
| `gitlab_transaction_event_etag_caching_cache_hit_total`        | Counter   |                    9.4 | Counter for ETag cache hit.                                                                         | `endpoint`                                          |
| `gitlab_transaction_event_etag_caching_header_missing_total`   | Counter   |                    9.4 | Counter for ETag cache miss - header missing                                                        | `endpoint`                                          |
| `gitlab_transaction_event_etag_caching_key_not_found_total`    | Counter   |                    9.4 | Counter for ETag cache miss - key not found                                                         | `endpoint`                                          |
| `gitlab_transaction_event_etag_caching_middleware_used_total`  | Counter   |                    9.4 | Counter for ETag middleware accessed                                                                | `endpoint`                                          |
| `gitlab_transaction_event_etag_caching_resource_changed_total` | Counter   |                    9.4 | Counter for ETag cache miss - resource changed                                                      | `endpoint`                                          |
| `gitlab_transaction_event_fork_repository_total`               | Counter   |                    9.4 | Counter for repository forks (RepositoryForkWorker). Only incremented when source repository exists |                                                     |
| `gitlab_transaction_event_import_repository_total`             | Counter   |                    9.4 | Counter for repository imports (RepositoryImportWorker)                                             |                                                     |
| `gitlab_transaction_event_push_branch_total`                   | Counter   |                    9.4 | Counter for all branch pushes                                                                       |                                                     |
| `gitlab_transaction_event_push_commit_total`                   | Counter   |                    9.4 | Counter for commits                                                                                 | `branch`                                            |
| `gitlab_transaction_event_push_tag_total`                      | Counter   |                    9.4 | Counter for tag pushes                                                                              |                                                     |
| `gitlab_transaction_event_rails_exception_total`               | Counter   |                    9.4 | Counter for number of rails exceptions                                                              |                                                     |
| `gitlab_transaction_event_receive_email_total`                 | Counter   |                    9.4 | Counter for received emails                                                                         | `handler`                                           |
| `gitlab_transaction_event_remote_mirrors_failed_total`         | Counter   |                   10.8 | Counter for failed remote mirrors                                                                   |                                                     |
| `gitlab_transaction_event_remote_mirrors_finished_total`       | Counter   |                   10.8 | Counter for finished remote mirrors                                                                 |                                                     |
| `gitlab_transaction_event_remote_mirrors_running_total`        | Counter   |                   10.8 | Counter for running remote mirrors                                                                  |                                                     |
| `gitlab_transaction_event_remove_branch_total`                 | Counter   |                    9.4 | Counter when a branch is removed for any repository                                                 |                                                     |
| `gitlab_transaction_event_remove_repository_total`             | Counter   |                    9.4 | Counter when a repository is removed                                                                |                                                     |
| `gitlab_transaction_event_remove_tag_total`                    | Counter   |                    9.4 | Counter when a tag is remove for any repository                                                     |                                                     |
| `gitlab_transaction_event_sidekiq_exception_total`             | Counter   |                    9.4 | Counter of Sidekiq exceptions                                                                       |                                                     |
| `gitlab_transaction_event_stuck_import_jobs_total`             | Counter   |                    9.4 | Count of stuck import jobs                                                                          | `projects_without_jid_count`, `projects_with_jid_count` |
| `gitlab_transaction_event_update_build_total`                  | Counter   |                    9.4 | Counter for update build for API `/jobs/request/:id`                                                |                                                     |
| `gitlab_transaction_new_redis_connections_total`               | Counter   |                    9.4 | Counter for new Redis connections                                                                   |                                                     |
| `gitlab_transaction_queue_duration_total`                      | Counter   |                    9.4 | Duration jobs were enqueued before processing                                                       |                                                     |
| `gitlab_transaction_rails_queue_duration_total`                | Counter   |                    9.4 | Measures latency between GitLab Workhorse forwarding a request to Rails                             | `controller`, `action`                              |
| `gitlab_transaction_view_duration_total`                       | Counter   |                    9.4 | Duration for views                                                                                  | `controller`, `action`, `view`                      |
| `gitlab_view_rendering_duration_seconds`                       | Histogram |                   10.2 | Duration for views (histogram)                                                                      | `controller`, `action`, `view`                      |
| `http_requests_total`                                          | Counter   |                    9.4 | Rack request count                                                                                  | `method`, `status`                                  |
| `http_request_duration_seconds`                                | Histogram |                    9.4 | HTTP response time from rack middleware                                                             | `method`                                            |
| `gitlab_transaction_db_count_total`                            | Counter   |                   13.1 | Counter for total number of SQL calls                                                               | `controller`, `action`                              |
| `gitlab_transaction_db_write_count_total`                      | Counter   |                   13.1 | Counter for total number of write SQL calls                                                         | `controller`, `action`                              |
| `gitlab_transaction_db_cached_count_total`                     | Counter   |                   13.1 | Counter for total number of cached SQL calls                                                        | `controller`, `action`                              |
| `http_elasticsearch_requests_duration_seconds` **(STARTER)**   | Histogram |                   13.1 | Elasticsearch requests duration during web transactions                                             | `controller`, `action`                              |
| `http_elasticsearch_requests_total` **(STARTER)**              | Counter   |                   13.1 | Elasticsearch requests count during web transactions                                                | `controller`, `action`                              |
| `pipelines_created_total`                                      | Counter   |                    9.4 | Counter of pipelines created                                                                        |                                                     |
| `rack_uncaught_errors_total`                                   | Counter   |                    9.4 | Rack connections handling uncaught errors count                                                     |                                                     |
| `user_session_logins_total`                                    | Counter   |                    9.4 | Counter of how many users have logged in since GitLab was started or restarted                                                            |                                                     |
| `upload_file_does_not_exist`                                   | Counter   | 10.7 in EE, 11.5 in CE | Number of times an upload record could not find its file                                            |                                                     |
| `failed_login_captcha_total`                                   | Gauge     |                   11.0 | Counter of failed CAPTCHA attempts during login                                                     |                                                     |
| `successful_login_captcha_total`                               | Gauge     |                   11.0 | Counter of successful CAPTCHA attempts during login                                                 |                                                     |
| `auto_devops_pipelines_completed_total`                        | Counter   |                   12.7 | Counter of completed Auto DevOps pipelines, labeled by status                                       |                                                     |
| `gitlab_metrics_dashboard_processing_time_ms`                  | Summary   |                  12.10 | Metrics dashboard processing time in milliseconds | service, stages |
| `action_cable_active_connections`                              | Gauge     |                   13.4 | Number of ActionCable WS clients currently connected | `server_mode` |
| `action_cable_pool_min_size`                                   | Gauge     |                   13.4 | Minimum number of worker threads in ActionCable thread pool | `server_mode` |
| `action_cable_pool_max_size`                                   | Gauge     |                   13.4 | Maximum number of worker threads in ActionCable thread pool | `server_mode` |
| `action_cable_pool_current_size`                               | Gauge     |                   13.4 | Current number of worker threads in ActionCable thread pool | `server_mode` |
| `action_cable_pool_largest_size`                               | Gauge     |                   13.4 | Largest number of worker threads observed so far in ActionCable thread pool | `server_mode` |
| `action_cable_pool_pending_tasks`                              | Gauge     |                   13.4 | Number of tasks waiting to be executed in ActionCable thread pool | `server_mode` |
| `action_cable_pool_tasks_total`                                | Gauge     |                   13.4 | Total number of tasks executed in ActionCable thread pool | `server_mode` |
| `gitlab_issuable_fast_count_by_state_total`                    | Counter   |                   13.5 | Total number of row count operations on issue/merge request list pages | |
| `gitlab_issuable_fast_count_by_state_failures_total`           | Counter   |                   13.5 | Number of soft-failed row count operations on issue/merge request list pages | |

## Metrics controlled by a feature flag

The following metrics can be controlled by feature flags:

| Metric                                                         | Feature Flag                                                       |
|:---------------------------------------------------------------|:-------------------------------------------------------------------|
| `gitlab_method_call_duration_seconds`                          | `prometheus_metrics_method_instrumentation`                        |
| `gitlab_view_rendering_duration_seconds`                       | `prometheus_metrics_view_instrumentation`                          |

## Sidekiq metrics

Sidekiq jobs may also gather metrics, and these metrics can be accessed if the
Sidekiq exporter is enabled: for example, using the `monitoring.sidekiq_exporter`
configuration option in `gitlab.yml`. These metrics are served from the
`/metrics` path on the configured port.

| Metric                                         | Type    | Since | Description | Labels |
|:---------------------------------------------- |:------- |:----- |:----------- |:------ |
| `sidekiq_jobs_cpu_seconds`                     | Histogram | 12.4 | Seconds of CPU time to run Sidekiq job                                                              | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_jobs_completion_seconds`              | Histogram | 12.2 | Seconds to complete Sidekiq job                                                                     | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_jobs_db_seconds`                      | Histogram | 12.9 | Seconds of DB time to run Sidekiq job                                                               | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_jobs_gitaly_seconds`                  | Histogram | 12.9 | Seconds of Gitaly time to run Sidekiq job                                                           | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_redis_requests_duration_seconds`      | Histogram | 13.1 | Duration in seconds that a Sidekiq job spent querying a Redis server                                | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_elasticsearch_requests_duration_seconds`      | Histogram | 13.1 | Duration in seconds that a Sidekiq job spent in requests to an Elasticsearch server                                | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_jobs_queue_duration_seconds`          | Histogram | 12.5 | Duration in seconds that a Sidekiq job was queued before being executed                             | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency` |
| `sidekiq_jobs_failed_total`                    | Counter   | 12.2 | Sidekiq jobs failed                                                                                 | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency` |
| `sidekiq_jobs_retried_total`                   | Counter   | 12.2 | Sidekiq jobs retried                                                                                | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency` |
| `sidekiq_jobs_dead_total`                      | Counter   | 13.7 | Sidekiq dead jobs (jobs that have run out of retries)                                               | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency` |
| `sidekiq_redis_requests_total`                 | Counter   | 13.1 | Redis requests during a Sidekiq job execution                                                       | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_elasticsearch_requests_total`         | Counter   | 13.1 | Elasticsearch requests during a Sidekiq job execution                                                       | `queue`, `boundary`, `external_dependencies`, `feature_category`, `job_status`, `urgency` |
| `sidekiq_running_jobs`                         | Gauge     | 12.2 | Number of Sidekiq jobs running                                                                      | `queue`, `boundary`, `external_dependencies`, `feature_category`, `urgency` |
| `sidekiq_concurrency`                          | Gauge     | 12.5 | Maximum number of Sidekiq jobs                                                                      |                                                                   |
| `geo_db_replication_lag_seconds`               | Gauge   | 10.2  | Database replication lag (seconds) | `url` |
| `geo_repositories`                             | Gauge   | 10.2  | Total number of repositories available on primary | `url` |
| `geo_repositories_synced`                      | Gauge   | 10.2  | Number of repositories synced on secondary | `url` |
| `geo_repositories_failed`                      | Gauge   | 10.2  | Number of repositories failed to sync on secondary | `url` |
| `geo_lfs_objects`                              | Gauge   | 10.2  | Total number of LFS objects available on primary | `url` |
| `geo_lfs_objects_synced`                       | Gauge   | 10.2  | Number of LFS objects synced on secondary | `url` |
| `geo_lfs_objects_failed`                       | Gauge   | 10.2  | Number of LFS objects failed to sync on secondary | `url` |
| `geo_attachments`                              | Gauge   | 10.2  | Total number of file attachments available on primary | `url` |
| `geo_attachments_synced`                       | Gauge   | 10.2  | Number of attachments synced on secondary | `url` |
| `geo_attachments_failed`                       | Gauge   | 10.2  | Number of attachments failed to sync on secondary | `url` |
| `geo_last_event_id`                            | Gauge   | 10.2  | Database ID of the latest event log entry on the primary | `url` |
| `geo_last_event_timestamp`                     | Gauge   | 10.2  | UNIX timestamp of the latest event log entry on the primary | `url` |
| `geo_cursor_last_event_id`                     | Gauge   | 10.2  | Last database ID of the event log processed by the secondary | `url` |
| `geo_cursor_last_event_timestamp`              | Gauge   | 10.2  | Last UNIX timestamp of the event log processed by the secondary | `url` |
| `geo_status_failed_total`                      | Counter | 10.2  | Number of times retrieving the status from the Geo Node failed | `url` |
| `geo_last_successful_status_check_timestamp`   | Gauge   | 10.2  | Last timestamp when the status was successfully updated | `url` |
| `geo_lfs_objects_synced_missing_on_primary`    | Gauge   | 10.7  | Number of LFS objects marked as synced due to the file missing on the primary | `url` |
| `geo_job_artifacts_synced_missing_on_primary`  | Gauge   | 10.7  | Number of job artifacts marked as synced due to the file missing on the primary | `url` |
| `geo_attachments_synced_missing_on_primary`    | Gauge   | 10.7  | Number of attachments marked as synced due to the file missing on the primary | `url` |
| `geo_repositories_checksummed`                 | Gauge   | 10.7  | Number of repositories checksummed on primary | `url` |
| `geo_repositories_checksum_failed`             | Gauge   | 10.7  | Number of repositories failed to calculate the checksum on primary | `url` |
| `geo_wikis_checksummed`                        | Gauge   | 10.7  | Number of wikis checksummed on primary | `url` |
| `geo_wikis_checksum_failed`                    | Gauge   | 10.7  | Number of wikis failed to calculate the checksum on primary | `url` |
| `geo_repositories_verified`                    | Gauge   | 10.7  | Number of repositories verified on secondary | `url` |
| `geo_repositories_verification_failed`         | Gauge   | 10.7  | Number of repositories failed to verify on secondary | `url` |
| `geo_repositories_checksum_mismatch`           | Gauge   | 10.7  | Number of repositories that checksum mismatch on secondary | `url` |
| `geo_wikis_verified`                           | Gauge   | 10.7  | Number of wikis verified on secondary | `url` |
| `geo_wikis_verification_failed`                | Gauge   | 10.7  | Number of wikis failed to verify on secondary | `url` |
| `geo_wikis_checksum_mismatch`                  | Gauge   | 10.7  | Number of wikis that checksum mismatch on secondary | `url` |
| `geo_repositories_checked`                     | Gauge   | 11.1  | Number of repositories that have been checked via `git fsck` | `url` |
| `geo_repositories_checked_failed`              | Gauge   | 11.1  | Number of repositories that have a failure from `git fsck` | `url` |
| `geo_repositories_retrying_verification`       | Gauge   | 11.2  | Number of repositories verification failures that Geo is actively trying to correct on secondary  | `url` |
| `geo_wikis_retrying_verification`              | Gauge   | 11.2  | Number of wikis verification failures that Geo is actively trying to correct on secondary | `url` |
| `geo_package_files`                            | Gauge   | 13.0  | Number of package files on primary | `url` |
| `geo_package_files_checksummed`                | Gauge   | 13.0  | Number of package files checksummed on primary | `url` |
| `geo_package_files_checksum_failed`            | Gauge   | 13.0  | Number of package files failed to calculate the checksum on primary | `url` |
| `geo_package_files_synced`                     | Gauge   | 13.3  | Number of syncable package files synced on secondary | `url` |
| `geo_package_files_failed`                     | Gauge   | 13.3  | Number of syncable package files failed to sync on secondary | `url` |
| `geo_package_files_registry`                   | Gauge   | 13.3  | Number of package files in the registry | `url` |
| `geo_terraform_state_versions`                 | Gauge   | 13.5  | Number of terraform state versions on primary | `url` |
| `geo_terraform_state_versions_checksummed`     | Gauge   | 13.5  | Number of terraform state versions checksummed on primary | `url` |
| `geo_terraform_state_versions_checksum_failed` | Gauge   | 13.5  | Number of terraform state versions failed to calculate the checksum on primary | `url` |
| `geo_terraform_state_versions_synced`          | Gauge   | 13.5  | Number of syncable terraform state versions synced on secondary | `url` |
| `geo_terraform_state_versions_failed`          | Gauge   | 13.5  | Number of syncable terraform state versions failed to sync on secondary | `url` |
| `geo_terraform_state_versions_registry`        | Gauge   | 13.5  | Number of terraform state versions in the registry | `url` |
| `global_search_bulk_cron_queue_size`           | Gauge   | 12.10 | Number of database records waiting to be synchronized to Elasticsearch | |
| `global_search_awaiting_indexing_queue_size`   | Gauge   | 13.2  | Number of database updates waiting to be synchronized to Elasticsearch while indexing is paused | |
| `geo_merge_request_diffs`                      | Gauge   | 13.4  | Number of merge request diffs on primary | `url` |
| `geo_merge_request_diffs_checksummed`          | Gauge   | 13.4  | Number of merge request diffs checksummed on primary | `url` |
| `geo_merge_request_diffs_checksum_failed`      | Gauge   | 13.4  | Number of merge request diffs failed to calculate the checksum on primary | `url` |
| `geo_merge_request_diffs_synced`               | Gauge   | 13.4  | Number of syncable merge request diffs synced on secondary | `url` |
| `geo_merge_request_diffs_failed`               | Gauge   | 13.4  | Number of syncable merge request diffs failed to sync on secondary | `url` |
| `geo_merge_request_diffs_registry`             | Gauge   | 13.4  | Number of merge request diffs in the registry | `url` |
| `geo_snippet_repositories`                     | Gauge   | 13.4  | Number of snippets on primary | `url` |
| `geo_snippet_repositories_checksummed`         | Gauge   | 13.4  | Number of snippets checksummed on primary | `url` |
| `geo_snippet_repositories_checksum_failed`     | Gauge   | 13.4  | Number of snippets failed to calculate the checksum on primary | `url` |
| `geo_snippet_repositories_synced`              | Gauge   | 13.4  | Number of syncable snippets synced on secondary | `url` |
| `geo_snippet_repositories_failed`              | Gauge   | 13.4  | Number of syncable snippets failed on secondary | `url` |
| `geo_snippet_repositories_registry`            | Gauge   | 13.4  | Number of syncable snippets in the registry | `url` |
| `limited_capacity_worker_running_jobs`         | Gauge   | 13.5  | Number of running jobs | `worker` |
| `limited_capacity_worker_max_running_jobs`     | Gauge   | 13.5  | Maximum number of running jobs | `worker` |
| `limited_capacity_worker_remaining_work_count` | Gauge   | 13.5  | Number of jobs waiting to be enqueued | `worker` |
| `destroyed_job_artifacts_count_total`          | Counter | 13.6  | Number of destroyed expired job artifacts | |

## Database load balancing metrics **(PREMIUM ONLY)**

The following metrics are available:

| Metric                            | Type      | Since                                                         | Description                            |
|:--------------------------------- |:--------- |:------------------------------------------------------------- |:-------------------------------------- |
| `db_load_balancing_hosts`         | Gauge     | [12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/13630)     | Current number of load balancing hosts |

## Database partitioning metrics **(PREMIUM ONLY)**

The following metrics are available:

| Metric                            | Type      | Since                                                         | Description                                                       |
|:--------------------------------- |:--------- |:------------------------------------------------------------- |:----------------------------------------------------------------- |
| `db_partitions_present`           | Gauge     | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353)  | Number of database partitions present                             |
| `db_partitions_missing`           | Gauge     | [13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/227353)  | Number of database partitions currently expected, but not present |

## Connection pool metrics

These metrics record the status of the database
[connection pools](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html),
and the metrics all have these labels:

- `class` - the Ruby class being recorded.
  - `ActiveRecord::Base` is the main database connection.
  - `Geo::TrackingBase` is the connection to the Geo tracking database, if
    enabled.
- `host` - the host name used to connect to the database.
- `port` - the port used to connect to the database.

| Metric                                        | Type  | Since | Description                                       |
|:----------------------------------------------|:------|:------|:--------------------------------------------------|
| `gitlab_database_connection_pool_size`        | Gauge | 13.0  | Total connection pool capacity                    |
| `gitlab_database_connection_pool_connections` | Gauge | 13.0  | Current connections in the pool                   |
| `gitlab_database_connection_pool_busy`        | Gauge | 13.0  | Connections in use where the owner is still alive |
| `gitlab_database_connection_pool_dead`        | Gauge | 13.0  | Connections in use where the owner is not alive   |
| `gitlab_database_connection_pool_idle`        | Gauge | 13.0  | Connections not in use                            |
| `gitlab_database_connection_pool_waiting`     | Gauge | 13.0  | Threads currently waiting on this queue           |

## Ruby metrics

Some basic Ruby runtime metrics are available:

| Metric                                   | Type      | Since | Description |
|:---------------------------------------- |:--------- |:----- |:----------- |
| `ruby_gc_duration_seconds`               | Counter   | 11.1  | Time spent by Ruby in GC |
| `ruby_gc_stat_...`                       | Gauge     | 11.1  | Various metrics from [GC.stat](https://ruby-doc.org/core-2.6.5/GC.html#method-c-stat) |
| `ruby_file_descriptors`                  | Gauge     | 11.1  | File descriptors per process |
| `ruby_sampler_duration_seconds`          | Counter   | 11.1  | Time spent collecting stats |
| `ruby_process_cpu_seconds_total`         | Gauge     | 12.0  | Total amount of CPU time per process |
| `ruby_process_max_fds`                   | Gauge     | 12.0  | Maximum number of open file descriptors per process |
| `ruby_process_resident_memory_bytes`     | Gauge     | 12.0  | Memory usage by process (RSS/Resident Set Size) |
| `ruby_process_unique_memory_bytes`       | Gauge     | 13.0  | Memory usage by process (USS/Unique Set Size) |
| `ruby_process_proportional_memory_bytes` | Gauge     | 13.0  | Memory usage by process (PSS/Proportional Set Size) |
| `ruby_process_start_time_seconds`        | Gauge     | 12.0  | UNIX timestamp of process start time |

## Unicorn Metrics

Unicorn specific metrics, when Unicorn is used.

| Metric                       | Type  | Since | Description                                        |
|:-----------------------------|:------|:------|:---------------------------------------------------|
| `unicorn_active_connections` | Gauge | 11.0  | The number of active Unicorn connections (workers) |
| `unicorn_queued_connections` | Gauge | 11.0  | The number of queued Unicorn connections           |
| `unicorn_workers`            | Gauge | 12.0  | The number of Unicorn workers                      |

## Puma Metrics

When Puma is used instead of Unicorn, the following metrics are available:

| Metric                            | Type    | Since | Description |
|:--------------------------------- |:------- |:----- |:----------- |
| `puma_workers`                    | Gauge   | 12.0  | Total number of workers |
| `puma_running_workers`            | Gauge   | 12.0  | Number of booted workers |
| `puma_stale_workers`              | Gauge   | 12.0  | Number of old workers |
| `puma_running`                    | Gauge   | 12.0  | Number of running threads |
| `puma_queued_connections`         | Gauge   | 12.0  | Number of connections in that worker's "to do" set waiting for a worker thread |
| `puma_active_connections`         | Gauge   | 12.0  | Number of threads processing a request |
| `puma_pool_capacity`              | Gauge   | 12.0  | Number of requests the worker is capable of taking right now |
| `puma_max_threads`                | Gauge   | 12.0  | Maximum number of worker threads |
| `puma_idle_threads`               | Gauge   | 12.0  | Number of spawned threads which are not processing a request |
| `puma_killer_terminations_total`  | Gauge   | 12.0  | Number of workers terminated by PumaWorkerKiller |

## Redis metrics

These client metrics are meant to complement Redis server metrics.
These metrics are broken down per [Redis
instance](https://docs.gitlab.com/omnibus/settings/redis.html#running-with-multiple-redis-instances).
These metrics all have a `storage` label which indicates the Redis
instance (`cache`, `shared_state` etc.).

| Metric                            | Type    | Since | Description |
|:--------------------------------- |:------- |:----- |:----------- |
| `gitlab_redis_client_exceptions_total`                    | Counter   | 13.2  | Number of Redis client exceptions, broken down by exception class |
| `gitlab_redis_client_requests_total`                    | Counter   | 13.2  | Number of Redis client requests |
| `gitlab_redis_client_requests_duration_seconds`                    | Histogram   | 13.2  | Redis request latency, excluding blocking commands |

## Metrics shared directory

GitLab's Prometheus client requires a directory to store metrics data shared between multi-process services.
Those files are shared among all instances running under Unicorn server.
The directory must be accessible to all running Unicorn's processes, or
metrics can't function correctly.

This directory's location is configured using environment variable `prometheus_multiproc_dir`.
For best performance, create this directory in `tmpfs`.

If GitLab is installed using [Omnibus GitLab](https://docs.gitlab.com/omnibus/)
and `tmpfs` is available, then GitLab configures the metrics directory for you.
