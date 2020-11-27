---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Repository checks

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3232) in GitLab 8.7.

Git has a built-in mechanism, [`git fsck`](https://git-scm.com/docs/git-fsck), to verify the
integrity of all data committed to a repository. GitLab administrators
can trigger such a check for a project via the project page under the
admin panel. The checks run asynchronously so it may take a few minutes
before the check result is visible on the project admin page. If the
checks failed you can see their output on in the [`repocheck.log`
file.](logs.md#repochecklog)

NOTE: **Note:**
It is OFF by default because it still causes too many false alarms.

## Periodic checks

When enabled, GitLab periodically runs a repository check on all project
repositories and wiki repositories in order to detect data corruption.
A project will be checked no more than once per month. If any projects
fail their repository checks all GitLab administrators will receive an email
notification of the situation. This notification is sent out once a week,
by default, midnight at the start of Sunday. Repositories with known check
failures can be found at `/admin/projects?last_repository_check_failed=1`.

## Disabling periodic checks

You can disable the periodic checks on the 'Settings' page of the admin
panel.

## What to do if a check failed

If the repository check fails for some repository you should look up the error
in the [`repocheck.log` file](logs.md#repochecklog) on disk:

- `/var/log/gitlab/gitlab-rails` for Omnibus installations
- `/home/git/gitlab/log` for installations from source

If the periodic repository check causes false alarms, you can clear all repository check states by
navigating to **Admin Area > Settings > Repository**
(`/admin/application_settings/repository`) and clicking **Clear all repository checks**.
