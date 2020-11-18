---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
disqus_identifier: 'https://docs.gitlab.com/ee/user/project/pipelines/settings.html'
type: reference, howto
---

# Pipeline settings

To reach the pipelines settings navigate to your project's
**Settings > CI/CD**.

The following settings can be configured per project.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, watch the video [GitLab CI Pipeline, Artifacts, and Environments](https://www.youtube.com/watch?v=PCKDICEe10s).
Watch also [GitLab CI pipeline tutorial for beginners](https://www.youtube.com/watch?v=Jav4vbUrqII).

## Git strategy

With Git strategy, you can choose the default way your repository is fetched
from GitLab in a job.

There are two options. Using:

- `git clone`, which is slower since it clones the repository from scratch
  for every job, ensuring that the local working copy is always pristine.
- `git fetch`, which is GitLab's default and faster as it re-uses the local working copy (falling
  back to clone if it doesn't exist).
  This is recommended, especially for [large repositories](../large_repositories/index.md#git-strategy).

The configured Git strategy can be overridden by the [`GIT_STRATEGY` variable](../runners/README.md#git-strategy)
in `.gitlab-ci.yml`.

## Git shallow clone

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/28919) in GitLab 12.0.

It is possible to limit the number of changes that GitLab CI/CD fetches when cloning
a repository. Setting a limit to `git depth` can speed up Pipelines execution.

In GitLab 12.0 and later, newly created projects automatically have a default
`git depth` value of `50`. The maximum allowed value is `1000`.

To disable shallow clone and make GitLab CI/CD fetch all branches and tags each time,
keep the value empty or set to `0`.

This value can also be [overridden by `GIT_DEPTH`](../large_repositories/index.md#shallow-cloning) variable in `.gitlab-ci.yml` file.

## Timeout

Timeout defines the maximum amount of time in minutes that a job is able run.
This is configurable under your project's **Settings > CI/CD > General pipelines settings**.
The default value is 60 minutes. Decrease the time limit if you want to impose
a hard limit on your jobs' running time or increase it otherwise. In any case,
if the job surpasses the threshold, it is marked as failed.

### Timeout overriding for runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17221) in GitLab 10.7.

Project defined timeout (either specific timeout set by user or the default
60 minutes timeout) may be [overridden for runners](../runners/README.md#set-maximum-job-timeout-for-a-runner).

## Maximum artifacts size **(CORE ONLY)**

For information about setting a maximum artifact size for a project, see
[Maximum artifacts size](../../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size).

## Custom CI configuration path

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/12509) in GitLab 9.4.
> - [Support for external `.gitlab-ci.yml` locations](https://gitlab.com/gitlab-org/gitlab/-/issues/14376) introduced in GitLab 12.6.

By default we look for the `.gitlab-ci.yml` file in the project's root
directory. If needed, you can specify an alternate path and filename, including locations outside the project.

To customize the path:

1. Go to the project's **Settings > CI / CD**.
1. Expand the **General pipelines** section.
1. Provide a value in the **Custom CI configuration path** field.
1. Click **Save changes**.

If the CI configuration is stored within the repository in a non-default
location, the path must be relative to the root directory. Examples of valid
paths and file names include:

- `.gitlab-ci.yml` (default)
- `.my-custom-file.yml`
- `my/path/.gitlab-ci.yml`
- `my/path/.my-custom-file.yml`

If hosting the CI configuration on an external site, the URL link must end with `.yml`:

- `http://example.com/generate/ci/config.yml`

If hosting the CI configuration in a different project within GitLab, the path must be relative
to the root directory in the other project. Include the group and project name at the end:

- `.gitlab-ci.yml@mygroup/another-project`
- `my/path/.my-custom-file.yml@mygroup/another-project`

Hosting the configuration file in a separate project allows stricter control of the
configuration file. For example:

- Create a public project to host the configuration file.
- Give write permissions on the project only to users who are allowed to edit the file.

Other users and projects can access the configuration file without being
able to edit it.

## Test coverage parsing

If you use test coverage in your code, GitLab can capture its output in the
job log using a regular expression. In the pipelines settings, search for the
"Test coverage parsing" section.

![Pipelines settings test coverage](img/pipelines_settings_test_coverage.png)

Leave blank if you want to disable it or enter a Ruby regular expression. You
can use <https://rubular.com> to test your regex. The regex returns the **last**
match found in the output.

If the pipeline succeeds, the coverage is shown in the merge request widget and
in the jobs table. If multiple jobs in the pipeline have coverage reports, they are
averaged.

![MR widget coverage](img/pipelines_test_coverage_mr_widget.png)

![Build status coverage](img/pipelines_test_coverage_build.png)

A few examples of known coverage tools for a variety of languages can be found
in the pipelines settings page.

### Code Coverage history

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/209121) the ability to download a `.csv` in GitLab 12.10.
> - [Graph introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33743) in GitLab 13.1.

To see the evolution of your project code coverage over time,
you can view a graph or download a CSV file with this data. From your project:

1. Go to **{chart}** **Project Analytics > Repository** to see the historic data for each job listed in the dropdown above the graph.
1. If you want a CSV file of that data, click **Download raw data (.csv)**

![Code coverage graph of a project over time](img/code_coverage_graph_v13_1.png)

### Removing color codes

Some test coverage tools output with ANSI color codes that aren't
parsed correctly by the regular expression. This causes coverage
parsing to fail.

Some coverage tools don't provide an option to disable color
codes in the output. If so, pipe the output of the coverage tool through a
small one line script that strips the color codes off.

For example:

```shell
lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
```

## Visibility of pipelines

Pipeline visibility is determined by:

- Your current [user access level](../../user/permissions.md).
- The **Public pipelines** project setting under your project's **Settings > CI/CD > General pipelines**.

NOTE: **Note:**
If the project visibility is set to **Private**, the [**Public pipelines** setting has no effect](../enable_or_disable_ci.md#per-project-user-setting).

This also determines the visibility of these related features:

- Job output logs
- Job artifacts
- The [pipeline security dashboard](../../user/application_security/security_dashboard/index.md#pipeline-security) **(ULTIMATE)**

Job logs and artifacts are [not visible for guest users and non-project members](https://gitlab.com/gitlab-org/gitlab/-/issues/25649).

If **Public pipelines** is enabled (default):

- For **public** projects, anyone can view the pipelines and related features.
- For **internal** projects, any logged in user except [external users](../../user/permissions.md#external-users) can view the pipelines
  and related features.
- For **private** projects, any project member (guest or higher) can view the pipelines
  and related features.

If **Public pipelines** is disabled:

- For **public** projects, anyone can view the pipelines, but only members
  (reporter or higher) can access the related features.
- For **internal** projects, any logged in user except [external users](../../user/permissions.md#external-users) can view the pipelines.
  However, only members (reporter or higher) can access the job related features.
- For **private** projects, only project members (reporter or higher)
  can view the pipelines or access the related features.

## Auto-cancel pending pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9362) in GitLab 9.1.

You can set pending or running pipelines to cancel automatically when a new pipeline runs on the same branch. You can enable this in the project settings:

1. Go to **Settings > CI / CD**.
1. Expand **General Pipelines**.
1. Check the **Auto-cancel redundant, pending pipelines** checkbox.
1. Click **Save changes**.

Note that only jobs with [interruptible](../yaml/README.md#interruptible) set to `true` are cancelled.

## Skip outdated deployment jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25276) in GitLab 12.9.

Your project may have multiple concurrent deployment jobs that are
scheduled to run within the same time frame.

This can lead to a situation where an older deployment job runs after a
newer one, which may not be what you want.

To avoid this scenario:

1. Go to **Settings > CI / CD**.
1. Expand **General pipelines**.
1. Check the **Skip outdated deployment jobs** checkbox.
1. Click **Save changes**.

When enabled, any older deployments job are skipped when a new deployment starts.

For more information, see [Deployment safety](../environments/deployment_safety.md).

## Retry outdated jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211339) in GitLab 13.6.

A deployment job can fail because a newer one has run. If you retry the failed deployment job, the
environment could be overwritten with older source code. If you click **Retry**, a modal warns you
about this and asks for confirmation.

For more information, see [Deployment safety](../environments/deployment_safety.md).

## Pipeline Badges

In the pipelines settings page you can find pipeline status and test coverage
badges for your project. The latest successful pipeline is used to read
the pipeline status and test coverage values.

Visit the pipelines settings page in your project to see the exact link to
your badges. You can also see ways to embed the badge image in your HTML or Markdown
pages.

![Pipelines badges](img/pipelines_settings_badges.png)

### Pipeline status badge

Depending on the status of your job, a badge can have the following values:

- pending
- running
- passed
- failed
- skipped
- canceled
- unknown

You can access a pipeline status badge image using the following link:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/pipeline.svg
```

#### Display only non-skipped status

If you want the pipeline status badge to only display the last non-skipped status, you can use the `?ignore_skipped=true` query parameter:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/pipeline.svg?ignore_skipped=true
```

### Test coverage report badge

GitLab makes it possible to define the regular expression for the [coverage report](#test-coverage-parsing),
that each job log is matched against. This means that each job in the
pipeline can have the test coverage percentage value defined.

The test coverage badge can be accessed using following link:

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg
```

If you would like to get the coverage report from a specific job, you can add
the `job=coverage_job_name` parameter to the URL. For example, the following
Markdown code embeds the test coverage report badge of the `coverage` job
into your `README.md`:

```markdown
![coverage](https://gitlab.com/gitlab-org/gitlab/badges/master/coverage.svg?job=coverage)
```

### Badge styles

Pipeline badges can be rendered in different styles by adding the `style=style_name` parameter to the URL. Two styles are available:

#### Flat (default)

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?style=flat
```

![Badge flat style](https://gitlab.com/gitlab-org/gitlab/badges/master/coverage.svg?job=coverage&style=flat)

#### Flat square

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/30120) in GitLab 11.8.

```plaintext
https://gitlab.example.com/<namespace>/<project>/badges/<branch>/coverage.svg?style=flat-square
```

![Badge flat square style](https://gitlab.com/gitlab-org/gitlab/badges/master/coverage.svg?job=coverage&style=flat-square)

### Custom badge text

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17555) in GitLab 13.1.

The text for a badge can be customized. This can be useful to differentiate between multiple coverage jobs that run in the same pipeline. Customize the badge text and width by adding the `key_text=custom_text` and `key_width=custom_key_width` parameters to the URL:

```plaintext
https://gitlab.com/gitlab-org/gitlab/badges/master/coverage.svg?job=karma&key_text=Frontend+Coverage&key_width=130
```

![Badge with custom text and width](https://gitlab.com/gitlab-org/gitlab/badges/master/coverage.svg?job=karma&key_text=Frontend+Coverage&key_width=130)

## Environment Variables

[Environment variables](../variables/README.md#gitlab-cicd-environment-variables) can be set in an environment to be available to a runner.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
