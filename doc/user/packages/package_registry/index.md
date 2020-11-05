---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Package Registry

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/221259) to GitLab Core in 13.3.

With the GitLab Package Registry, you can use GitLab as a private or public registry
for a variety of common package managers. You can publish and share
packages, which can be easily consumed as a dependency in downstream projects.

## View packages

You can view packages for your project or group.

1. Go to the project or group.
1. Go to **Packages & Registries > Package Registry**.

You can search, sort, and filter packages on this page.

For information on how to create and upload a package, view the GitLab documentation for your package type.

## Use GitLab CI/CD to build packages

You can use [GitLab CI/CD](../../../ci/README.md) to build packages.
For Maven, NuGet, NPM, Conan, and PyPI packages, and Composer dependencies, you can
authenticate with GitLab by using the `CI_JOB_TOKEN`.

CI/CD templates, which you can use to get started, are in [this repo](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

Learn more about [using CI/CD to build Maven packages](../maven_repository/index.md#creating-maven-packages-with-gitlab-cicd), [NPM packages](../npm_registry/index.md#publishing-a-package-with-cicd), [Composer packages](../composer_repository/index.md#publish-a-composer-package-by-using-cicd), [NuGet Packages](../nuget_repository/index.md#publishing-a-nuget-package-with-cicd), [Conan Packages](../conan_repository/index.md#publish-a-conan-package-by-using-cicd), [PyPI packages](../pypi_repository/index.md#using-gitlab-ci-with-pypi-packages), and [generic packages](../generic_packages/index.md#publish-a-generic-package-by-using-cicd).

If you use CI/CD to build a package, extended activity
information is displayed when you view the package details:

![Package CI/CD activity](img/package_activity_v12_10.png)

When using Maven and NPM, you can view which pipeline published the package, as well as the commit and
user who triggered it.

## Download a package

To download a package:

1. Go to **Packages & Registries > Package Registry**.
1. Click the name of the package you want to download.
1. In the **Activity** section, click the name of the package you want to download.

## Delete a package

You cannot edit a package after you publish it in the Package Registry. Instead, you
must delete and recreate it.

To delete a package, you must have suitable [permissions](../../permissions.md).

You can delete packages by using [the API](../../../api/packages.md#delete-a-project-package) or the UI.

To delete a package in the UI, from your group or project:

1. Go to **Packages & Registries > Package Registry**.
1. Find the name of the package you want to delete.
1. Click **Delete**.

The package is permanently deleted.

## Disable the Package Registry

The Package Registry is automatically enabled.

If you are using a self-managed instance of GitLab, your administrator can remove
the menu item, **Packages & Registries**, from the GitLab sidebar. For more information,
see the [administration documentation](../../../administration/packages/index.md).

You can also remove the Package Registry for your project specifically:

1. In your project, go to **Settings > General**.
1. Expand the **Visibility, project features, permissions** section and disable the
   **Packages** feature.
1. Click **Save changes**.

The **Packages & Registries > Package Registry** entry is removed from the sidebar.

## Package workflows

Learn how to use the GitLab Package Registry to build your own custom package workflow.

- [Use a project as a package registry](../workflows/project_registry.md) to publish all of your packages to one project.
- Publish multiple different packages from one [monorepo project](../workflows/monorepo.md).
