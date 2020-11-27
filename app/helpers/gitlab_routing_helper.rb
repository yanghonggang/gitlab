# frozen_string_literal: true

# Shorter routing method for some project items
module GitlabRoutingHelper
  extend ActiveSupport::Concern

  include API::Helpers::RelatedResourcesHelpers
  included do
    Gitlab::Routing.includes_helpers(self)
  end

  # Project
  def project_tree_path(project, ref = nil, *args)
    namespace_project_tree_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
  end

  def project_commits_path(project, ref = nil, *args)
    namespace_project_commits_path(project.namespace, project, ref || @ref || project.repository.root_ref, *args) # rubocop:disable Cop/ProjectPathHelper
  end

  def project_ref_path(project, ref_name, *args)
    project_commits_path(project, ref_name, *args)
  end

  def environment_path(environment, *args)
    project_environment_path(environment.project, environment, *args)
  end

  def environment_metrics_path(environment, *args)
    metrics_project_environment_path(environment.project, environment, *args)
  end

  def environment_delete_path(environment, *args)
    expose_path(api_v4_projects_environments_path(id: environment.project.id, environment_id: environment.id))
  end

  def issue_path(entity, *args)
    project_issue_path(entity.project, entity, *args)
  end

  def merge_request_path(entity, *args)
    project_merge_request_path(entity.project, entity, *args)
  end

  def pipeline_path(pipeline, *args)
    project_pipeline_path(pipeline.project, pipeline.id, *args)
  end

  def issue_url(entity, *args)
    project_issue_url(entity.project, entity, *args)
  end

  def merge_request_url(entity, *args)
    project_merge_request_url(entity.project, entity, *args)
  end

  def pipeline_url(pipeline, *args)
    project_pipeline_url(pipeline.project, pipeline.id, *args)
  end

  def pipeline_job_url(pipeline, build, *args)
    project_job_url(pipeline.project, build.id, *args)
  end

  def commits_url(entity, *args)
    project_commits_url(entity.project, entity.source_ref, *args)
  end

  def commit_url(entity, *args)
    project_commit_url(entity.project, entity.sha, *args)
  end

  def release_url(entity, *args)
    project_release_url(entity.project, entity, *args)
  end

  def preview_markdown_path(parent, *args)
    return group_preview_markdown_path(parent, *args) if parent.is_a?(Group)

    if @snippet.is_a?(PersonalSnippet)
      preview_markdown_snippets_path
    else
      preview_markdown_project_path(parent, *args)
    end
  end

  def edit_milestone_path(entity, *args)
    if entity.resource_parent.is_a?(Group)
      edit_group_milestone_path(entity.resource_parent, entity, *args)
    else
      edit_project_milestone_path(entity.resource_parent, entity, *args)
    end
  end

  def toggle_subscription_path(entity, *args)
    if entity.is_a?(Issue)
      toggle_subscription_project_issue_path(entity.project, entity)
    else
      toggle_subscription_project_merge_request_path(entity.project, entity)
    end
  end

  def toggle_award_emoji_personal_snippet_path(*args)
    toggle_award_emoji_snippet_path(*args)
  end

  def toggle_award_emoji_project_project_snippet_path(*args)
    toggle_award_emoji_project_snippet_path(*args)
  end

  def toggle_award_emoji_project_project_snippet_url(*args)
    toggle_award_emoji_project_snippet_url(*args)
  end

  ## Members
  def project_members_url(project, *args)
    project_project_members_url(project, *args)
  end

  def project_member_path(project_member, *args)
    project_project_member_path(project_member.source, project_member)
  end

  def request_access_project_members_path(project, *args)
    request_access_project_project_members_path(project)
  end

  def leave_project_members_path(project, *args)
    leave_project_project_members_path(project)
  end

  def approve_access_request_project_member_path(project_member, *args)
    approve_access_request_project_project_member_path(project_member.source, project_member)
  end

  def resend_invite_project_member_path(project_member, *args)
    resend_invite_project_project_member_path(project_member.source, project_member)
  end

  # Groups

  ## Members
  def group_members_url(group, *args)
    group_group_members_url(group, *args)
  end

  def group_member_path(group_member, *args)
    group_group_member_path(group_member.source, group_member)
  end

  def request_access_group_members_path(group, *args)
    request_access_group_group_members_path(group)
  end

  def leave_group_members_path(group, *args)
    leave_group_group_members_path(group)
  end

  def approve_access_request_group_member_path(group_member, *args)
    approve_access_request_group_group_member_path(group_member.source, group_member)
  end

  def resend_invite_group_member_path(group_member, *args)
    resend_invite_group_group_member_path(group_member.source, group_member)
  end

  # Artifacts

  # Rails path generators are slow because they need to do large regex comparisons
  # against the arguments. We can speed this up 10x by generating the strings directly.

  # /*namespace_id/:project_id/-/jobs/:job_id/artifacts/download(.:format)
  def fast_download_project_job_artifacts_path(project, job, params = {})
    expose_fast_artifacts_path(project, job, :download, params)
  end

  # /*namespace_id/:project_id/-/jobs/:job_id/artifacts/keep(.:format)
  def fast_keep_project_job_artifacts_path(project, job)
    expose_fast_artifacts_path(project, job, :keep)
  end

  #  /*namespace_id/:project_id/-/jobs/:job_id/artifacts/browse(/*path)
  def fast_browse_project_job_artifacts_path(project, job)
    expose_fast_artifacts_path(project, job, :browse)
  end

  def expose_fast_artifacts_path(project, job, action, params = {})
    path = "#{project.full_path}/-/jobs/#{job.id}/artifacts/#{action}"

    unless params.empty?
      path += "?#{params.to_query}"
    end

    Gitlab::Utils.append_path(Gitlab.config.gitlab.relative_url_root, path)
  end

  def artifacts_action_path(path, project, build)
    action, path_params = path.split('/', 2)
    args = [project, build, path_params]

    case action
    when 'download'
      download_project_job_artifacts_path(*args)
    when 'browse'
      browse_project_job_artifacts_path(*args)
    when 'file'
      file_project_job_artifacts_path(*args)
    when 'raw'
      raw_project_job_artifacts_path(*args)
    end
  end

  # Pipeline Schedules
  def pipeline_schedules_path(project, *args)
    project_pipeline_schedules_path(project, *args)
  end

  def pipeline_schedule_path(schedule, *args)
    project = schedule.project
    project_pipeline_schedule_path(project, schedule, *args)
  end

  def edit_pipeline_schedule_path(schedule)
    project = schedule.project
    edit_project_pipeline_schedule_path(project, schedule)
  end

  def play_pipeline_schedule_path(schedule, *args)
    project = schedule.project
    play_project_pipeline_schedule_path(project, schedule, *args)
  end

  def take_ownership_pipeline_schedule_path(schedule, *args)
    project = schedule.project
    take_ownership_project_pipeline_schedule_path(project, schedule, *args)
  end

  def gitlab_snippet_path(snippet, *args)
    if snippet.is_a?(ProjectSnippet)
      project_snippet_path(snippet.project, snippet, *args)
    else
      new_args = snippet_query_params(snippet, *args)
      snippet_path(snippet, *new_args)
    end
  end

  def gitlab_snippet_url(snippet, *args)
    if snippet.is_a?(ProjectSnippet)
      project_snippet_url(snippet.project, snippet, *args)
    else
      new_args = snippet_query_params(snippet, *args)
      snippet_url(snippet, *new_args)
    end
  end

  def gitlab_dashboard_snippets_path(snippet, *args)
    if snippet.is_a?(ProjectSnippet)
      project_snippets_path(snippet.project, *args)
    else
      dashboard_snippets_path
    end
  end

  def gitlab_raw_snippet_path(snippet, *args)
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_path(snippet.project, snippet, *args)
    else
      new_args = snippet_query_params(snippet, *args)
      raw_snippet_path(snippet, *new_args)
    end
  end

  def gitlab_raw_snippet_url(snippet, *args)
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_url(snippet.project, snippet, *args)
    else
      new_args = snippet_query_params(snippet, *args)
      raw_snippet_url(snippet, *new_args)
    end
  end

  def gitlab_raw_snippet_blob_url(snippet, path, ref = nil, **options)
    params = {
      snippet_id: snippet,
      ref: ref || snippet.repository.root_ref,
      path: path
    }

    if snippet.is_a?(ProjectSnippet)
      project_snippet_blob_raw_url(snippet.project, **params, **options)
    else
      snippet_blob_raw_url(**params, **options)
    end
  end

  def gitlab_raw_snippet_blob_path(snippet, path, ref = nil, **options)
    gitlab_raw_snippet_blob_url(snippet, path, ref, only_path: true, **options)
  end

  def gitlab_snippet_notes_path(snippet, *args)
    new_args = snippet_query_params(snippet, *args)
    snippet_notes_path(snippet, *new_args)
  end

  def gitlab_snippet_notes_url(snippet, *args)
    new_args = snippet_query_params(snippet, *args)
    snippet_notes_url(snippet, *new_args)
  end

  def gitlab_snippet_note_path(snippet, note, *args)
    new_args = snippet_query_params(snippet, *args)
    snippet_note_path(snippet, note, *new_args)
  end

  def gitlab_snippet_note_url(snippet, note, *args)
    new_args = snippet_query_params(snippet, *args)
    snippet_note_url(snippet, note, *new_args)
  end

  def gitlab_toggle_award_emoji_snippet_note_path(snippet, note, *args)
    new_args = snippet_query_params(snippet, *args)
    toggle_award_emoji_snippet_note_path(snippet, note, *new_args)
  end

  def gitlab_toggle_award_emoji_snippet_note_url(snippet, note, *args)
    new_args = snippet_query_params(snippet, *args)
    toggle_award_emoji_snippet_note_url(snippet, note, *new_args)
  end

  def gitlab_toggle_award_emoji_snippet_path(snippet, *args)
    new_args = snippet_query_params(snippet, *args)
    toggle_award_emoji_snippet_path(snippet, *new_args)
  end

  def gitlab_toggle_award_emoji_snippet_url(snippet, *args)
    new_args = snippet_query_params(snippet, *args)
    toggle_award_emoji_snippet_url(snippet, *new_args)
  end

  # Wikis

  def wiki_path(wiki, **options)
    Gitlab::UrlBuilder.wiki_url(wiki, only_path: true, **options)
  end

  def wiki_page_path(wiki, page, **options)
    Gitlab::UrlBuilder.wiki_page_url(wiki, page, only_path: true, **options)
  end

  private

  def snippet_query_params(snippet, *args)
    opts = case args.last
           when Hash
             args.pop
           when ActionController::Parameters
             args.pop.to_h
           else
             {}
           end

    args << opts
  end
end

GitlabRoutingHelper.include_if_ee('EE::GitlabRoutingHelper')
