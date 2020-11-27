---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Composer packages in the Package Registry

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15886) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

Publish [Composer](https://getcomposer.org/) packages in your project's Package Registry.
Then, install the packages whenever you need to use them as a dependency.

Only Composer 1.x is supported. Consider contributing or even adding support for
[Composer 2.0 in the Package Registry](https://gitlab.com/gitlab-org/gitlab/-/issues/259840).

## Create a Composer package

If you do not have a Composer package, create one and check it in to
a repository. This example shows a GitLab repository, but the repository
can be any public or private repository.

1. Create a directory called `my-composer-package` and change to that directory:

   ```shell
   mkdir my-composer-package && cd my-composer-package
   ```

1. Run [`composer init`](https://getcomposer.org/doc/03-cli.md#init) and answer the prompts.

   For namespace, enter your unique [namespace](../../../user/group/index.md#namespaces), like your GitLab username or group name.

   A file called `composer.json` is created:

   ```json
   {
     "name": "<namespace>/composer-test",
     "description": "Library XY",
     "type": "library",
     "license": "GPL-3.0-only",
     "authors": [
        {
            "name": "John Doe",
            "email": "john@example.com"
        }
     ],
     "require": {}
   }
   ```

1. Run Git commands to tag the changes and push them to your repository:

   ```shell
   git init
   git add composer.json
   git commit -m 'Composer package test'
   git tag v1.0.0
   git remote add origin git@gitlab.example.com:<namespace>/<project-name>.git
   git push --set-upstream origin master
   git push origin v1.0.0
   ```

The package is now in your GitLab Package Registry.

## Publish a Composer package by using the API

Publish a Composer package to the Package Registry,
so that anyone who can access the project can use the package as a dependency.

Prerequisites:

- A package in a GitLab repository.
- A valid `composer.json` file.
- The Packages feature is enabled in a GitLab repository.
- The project ID, which is on the project's home page.
- A [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `api`.

  NOTE: **Note:**
  [Deploy tokens](../../project/deploy_tokens/index.md) are
  [not yet supported](https://gitlab.com/gitlab-org/gitlab/-/issues/240897) for use with Composer.

To publish the package:

- Send a `POST` request to the [Packages API](../../../api/packages.md).

  For example, you can use `curl`:

  ```shell
  curl --data tag=<tag> "https://__token__:<personal-access-token>@gitlab.example.com/api/v4/projects/<project_id>/packages/composer"
  ```

  - `<personal-access-token>` is your personal access token.
  - `<project_id>` is your project ID.
  - `<tag>` is the Git tag name of the version you want to publish.
     To publish a branch, use `branch=<branch>` instead of `tag=<tag>`.

You can view the published package by going to **Packages & Registries > Package Registry** and
selecting the **Composer** tab.

## Publish a Composer package by using CI/CD

You can publish a Composer package to the Package Registry as part of your CI/CD process.

1. Specify a `CI_JOB_TOKEN` in your `.gitlab-ci.yml` file:

   ```yaml
   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - 'curl --header "Job-Token: $CI_JOB_TOKEN" --data tag=<tag> "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/packages/composer"'
   ```

1. Run the pipeline.

You can view the published package by going to **Packages & Registries > Package Registry** and selecting the **Composer** tab.

### Use a CI/CD template

A more detailed Composer CI/CD file is also available as a `.gitlab-ci.yml` template:

1. On the left sidebar, click **Project overview**.
1. Above the file list, click **Set up CI/CD**. If this button is not available, select **CI/CD Configuration** and then **Edit**.
1. From the **Apply a template** list, select **Composer**.

CAUTION: **Warning:**
Do not save unless you want to overwrite the existing CI/CD file.

## Install a Composer package

Install a package from the Package Registry so you can use it as a dependency.

Prerequisites:

- A package in the Package Registry.
- The group ID, which is on the group's home page.
- A [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to, at minimum, `read_api`.

  NOTE: **Note:**
  [Deploy tokens](../../project/deploy_tokens/index.md) are
  [not yet supported](https://gitlab.com/gitlab-org/gitlab/-/issues/240897) for use with Composer.

To install a package:

1. Add the Package Registry URL to your project's `composer.json` file, along with the package name and version you want to install:

   - Connect to the Package Registry for your group:

   ```shell
   composer config repositories.<group_id> composer https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/
   ```

   - Set the required package version:

   ```shell
   composer require <package_name>:<version>
   ```

   Result in the `composer.json` file:

   ```json
   {
     ...
     "repositories": {
       "<group_id>": {
         "type": "composer",
         "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/"
       },
       ...
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset repositories.<group_id>
   ```

   - `<group_id>` is the group ID.
   - `<package_name>` is the package name defined in your package's `composer.json` file.
   - `<version>` is the package version.

1. Create an `auth.json` file with your GitLab credentials:

   ```shell
   composer config gitlab-token.<DOMAIN-NAME> <personal_access_token>
   ```

   Result in the `auth.json` file:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": "<personal_access_token>",
       ...
     }
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset --auth gitlab-token.<DOMAIN-NAME>
   ```

   - `<DOMAIN-NAME>` is the GitLab instance URL `gitlab.com` or `gitlab.example.com`.
   - `<personal_access_token>` with the scope set to `read_api`.

1. If you are on a GitLab self-managed instance, add `gitlab-domains` to `composer.json`.

   ```shell
   composer config gitlab-domains gitlab01.example.com gitlab02.example.com
   ```

   Result in the `composer.json` file:

   ```json
   {
     ...
     "repositories": [
       { "type": "composer", "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/" }
     ],
     "config": {
       ...
       "gitlab-domains": ["gitlab01.example.com", "gitlab02.example.com"]
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   You can unset this with the command:

   ```shell
   composer config --unset gitlab-domains
   ```

   NOTE: **Note:**
   On GitLab.com, Composer uses the GitLab token from `auth.json` as a private token by default.
   Without the `gitlab-domains` definition in `composer.json`, Composer uses the GitLab token
   as basic-auth, with the token as a username and a blank password. This results in a 401 error.

Output indicates that the package has been successfully installed.

CAUTION: **Important:**
Never commit the `auth.json` file to your repository. To install packages from a CI/CD job,
consider using the [`composer config`](https://getcomposer.org/doc/articles/handling-private-packages-with-satis.md#authentication) tool with your personal access token
stored in a [GitLab CI/CD environment variable](../../../ci/variables/README.md) or in
[HashiCorp Vault](../../../ci/secrets/index.md).
