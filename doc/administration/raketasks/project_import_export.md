---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project import/export administration **(CORE ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/3050) in GitLab 8.9.
> - From GitLab 11.3, import/export can use object storage automatically.

GitLab provides Rake tasks relating to project import and export. For more information, see:

- [Project import/export documentation](../../user/project/settings/import_export.md).
- [Project import/export API](../../api/project_import_export.md).
- [Developer documentation: project import/export](../../development/import_export.md)

## Project import status

You can query an import through the [Project import/export API](../../api/project_import_export.md#import-status).
As described in the API documentation, the query may return an import error or exceptions.

## Import large projects

If you have a larger project, consider using a Rake task, as described in our [developer documentation](../../development/import_project.md#importing-via-a-rake-task).

## Import/export tasks

The GitLab import/export version can be checked by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:version

# Installations from source
bundle exec rake gitlab:import_export:version RAILS_ENV=production
```

The current list of DB tables to export can be listed by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:data

# Installations from source
bundle exec rake gitlab:import_export:data RAILS_ENV=production
```

Note the following:

- Importing is only possible if the version of the import and export GitLab instances are
  compatible as described in the [Version history](../../user/project/settings/import_export.md#version-history).
- The project import option must be enabled in
  application settings (`/admin/application_settings/general`) under **Import sources**, which is available
  under **Admin Area > Settings > Visibility and access controls**.
- The exports are stored in a temporary [shared directory](../../development/shared_files.md)
  and are deleted every 24 hours by a specific worker.
