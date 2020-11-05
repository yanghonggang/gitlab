---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Updating GitLab

Depending on the installation method and your GitLab version, there are multiple
update guides.

There are currently 3 official ways to install GitLab:

- [Omnibus packages](#omnibus-packages)
- [Source installation](#installation-from-source)
- [Docker installation](#installation-using-docker)

Based on your installation, choose a section below that fits your needs.

## Omnibus Packages

- The [Omnibus update guide](https://docs.gitlab.com/omnibus/update/README.html)
  contains the steps needed to update an Omnibus GitLab package.

## Installation from source

- [Upgrading Community Edition and Enterprise Edition from
  source](upgrading_from_source.md) - The guidelines for upgrading Community
  Edition and Enterprise Edition from source.
- [Patch versions](patch_versions.md) guide includes the steps needed for a
  patch version, such as 6.2.0 to 6.2.1, and apply to both Community and Enterprise
  Editions.

In the past we used separate documents for the upgrading instructions, but we
have since switched to using a single document. The old upgrading guidelines
can still be found in the Git repository:

- [Old upgrading guidelines for Community Edition](https://gitlab.com/gitlab-org/gitlab-foss/tree/11-8-stable/doc/update)
- [Old upgrading guidelines for Enterprise Edition](https://gitlab.com/gitlab-org/gitlab/tree/11-8-stable-ee/doc/update)

## Installation using Docker

GitLab provides official Docker images for both Community and Enterprise
editions. They are based on the Omnibus package and instructions on how to
update them are in [a separate document](https://docs.gitlab.com/omnibus/docker/README.html).

## Upgrading without downtime

Starting with GitLab 9.1.0 it's possible to upgrade to a newer major, minor, or
patch version of GitLab without having to take your GitLab instance offline.
However, for this to work there are the following requirements:

- You can only upgrade 1 minor release at a time. So from 9.1 to 9.2, not to
   9.3.
- You have to use [post-deployment
   migrations](../development/post_deployment_migrations.md) (included in
   zero downtime update steps below).
- You are using PostgreSQL. Starting from GitLab 12.1, MySQL is not supported.
- Multi-node GitLab instance. Single-node instances may experience brief interruptions
  [as services restart (Puma in particular)](https://docs.gitlab.com/omnibus/update/README.html#single-node-deployment).

Most of the time you can safely upgrade from a patch release to the next minor
release if the patch release is not the latest. For example, upgrading from
9.1.1 to 9.2.0 should be safe even if 9.1.2 has been released. We do recommend
you check the release posts of any releases between your current and target
version just in case they include any migrations that may require you to upgrade
1 release at a time.

Some releases may also include so called "background migrations". These
migrations are performed in the background by Sidekiq and are often used for
migrating data. Background migrations are only added in the monthly releases.

Certain major/minor releases may require a set of background migrations to be
finished. To guarantee this such a release will process any remaining jobs
before continuing the upgrading procedure. While this won't require downtime
(if the above conditions are met) we recommend users to keep at least 1 week
between upgrading major/minor releases, allowing the background migrations to
finish. The time necessary to complete these migrations can be reduced by
increasing the number of Sidekiq workers that can process jobs in the
`background_migration` queue. To see the size of this queue,
[Check for background migrations before upgrading](#checking-for-background-migrations-before-upgrading).

As a rule of thumb, any database smaller than 10 GB won't take too much time to
upgrade; perhaps an hour at most per minor release. Larger databases however may
require more time, but this is highly dependent on the size of the database and
the migrations that are being performed.

### Examples

To help explain this, let's look at some examples.

**Example 1:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. When GitLab 9.5.0 is released this
installation can be safely upgraded to 9.5.0 without requiring downtime if the
requirements mentioned above are met. You can also skip 9.5.0 and upgrade to
9.5.1 once it's released, but you **can not** upgrade straight to 9.6.0; you
_have_ to first upgrade to a 9.5.x release.

**Example 2:** You are running a large GitLab installation using version 9.4.2,
which is the latest patch release of 9.4. GitLab 9.5 includes some background
migrations, and 10.0 will require these to be completed (processing any
remaining jobs for you). Skipping 9.5 is not possible without downtime, and due
to the background migrations would require potentially hours of downtime
depending on how long it takes for the background migrations to complete. To
work around this you will have to upgrade to 9.5.x first, then wait at least a
week before upgrading to 10.0.

**Example 3:** You use MySQL as the database for GitLab. Any upgrade to a new
major/minor release will require downtime. If a release includes any background
migrations this could potentially lead to hours of downtime, depending on the
size of your database. To work around this you will have to use PostgreSQL and
meet the other online upgrade requirements mentioned above.

### Steps

Steps to [upgrade without downtime](https://docs.gitlab.com/omnibus/update/README.html#zero-downtime-updates).

## Checking for background migrations before upgrading

Certain major/minor releases may require a set of background migrations to be
finished. The number of remaining migrations jobs can be found by running the
following command:

**For Omnibus installations**

If using GitLab 12.9 and newer, run:

```shell
sudo gitlab-rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

If using GitLab 12.8 and older, run the following using a [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
puts Sidekiq::Queue.new("background_migration").size
Sidekiq::ScheduledSet.new.select { |r| r.klass == 'BackgroundMigrationWorker' }.size
```

---

**For installations from source**

If using GitLab 12.9 and newer, run:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rails runner -e production 'puts Gitlab::BackgroundMigration.remaining'
```

If using GitLab 12.8 and older, run the following using a [Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
puts Sidekiq::Queue.new("background_migration").size
Sidekiq::ScheduledSet.new.select { |r| r.klass == 'BackgroundMigrationWorker' }.size
```

### What do I do if my background migrations are stuck?

CAUTION: **Warning:**
The following operations can disrupt your GitLab performance.

NOTE: **Note:**
It is safe to re-execute these commands, especially if you have 1000+ pending jobs which would likely overflow your runtime memory.

**For Omnibus installations**

```shell
# Start the rails console
sudo gitlab-rails c

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

**For installations from source**

```shell
# Start the rails console
sudo -u git -H bundle exec rails RAILS_ENV=production

# Execute the following in the rails console
scheduled_queue = Sidekiq::ScheduledSet.new
pending_job_classes = scheduled_queue.select { |job| job["class"] == "BackgroundMigrationWorker" }.map { |job| job["args"].first }.uniq
pending_job_classes.each { |job_class| Gitlab::BackgroundMigration.steal(job_class) }
```

## Upgrading to a new major version

Major versions are reserved for backwards incompatible changes. We recommend that
you first upgrade to the latest available minor version within your major version.
Please follow the [Upgrade Recommendations](../policy/maintenance.md#upgrade-recommendations)
to identify a supported upgrade path.

Before upgrading to a new major version, you should ensure that any background
migration jobs from previous releases have been completed. To see the current size
of the `background_migration` queue, [check for background migrations before upgrading](#checking-for-background-migrations-before-upgrading).

## Upgrading between editions

GitLab comes in two flavors: [Community Edition](https://about.gitlab.com/features/#community) which is MIT licensed,
and [Enterprise Edition](https://about.gitlab.com/features/#enterprise) which builds on top of the Community Edition and
includes extra features mainly aimed at organizations with more than 100 users.

Below you can find some guides to help you change editions easily.

### Community to Enterprise Edition

NOTE: **Note:**
The following guides are for subscribers of the Enterprise Edition only.

If you wish to upgrade your GitLab installation from Community to Enterprise
Edition, follow the guides below based on the installation method:

- [Source CE to EE update guides](upgrading_from_ce_to_ee.md) - The steps are very similar
  to a version upgrade: stop the server, get the code, update configuration files for
  the new functionality, install libraries and do migrations, update the init
  script, start the application and check its status.
- [Omnibus CE to EE](https://docs.gitlab.com/omnibus/update/README.html#updating-community-edition-to-enterprise-edition) - Follow this guide to update your Omnibus
  GitLab Community Edition to the Enterprise Edition.

### Enterprise to Community Edition

If you need to downgrade your Enterprise Edition installation back to Community
Edition, you can follow [this guide](../downgrade_ee_to_ce/README.md) to make the process as smooth as
possible.

## Version specific upgrading instructions

### 13.6.0

The required Git version is Git v2.29 or higher.

### 13.3.0

The recommended Git version is Git v2.28. The minimum required version of Git
v2.24 remains the same.

### 13.2.0

GitLab installations that have multiple web nodes will need to be
[upgraded to 13.1](#1310) before upgrading to 13.2 (and later) due to a
breaking change in Rails that can result in authorization issues.

GitLab 13.2.0 [remediates](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35492) an [email verification bypass](https://about.gitlab.com/releases/2020/05/27/security-release-13-0-1-released/).
After upgrading, if some of your users are unexpectedly encountering 404 or 422 errors when signing in,
or "blocked" messages when using the command line,
their accounts may have been un-confirmed.
In that case, please ask them to check their email for a re-confirmation link.
For more information, see our discussion of [Email confirmation issues](../user/upgrade_email_bypass.md).

GitLab 13.2.0 relies on the `btree_gist` extension for PostgreSQL. For installations with an externally managed PostgreSQL setup, please make sure to
[install the extension manually](https://www.postgresql.org/docs/11/sql-createextension.html) before upgrading GitLab if the database user for GitLab
is not a superuser. This is not necessary for installations using a GitLab managed PostgreSQL database.

### 13.1.0

In 13.1.0, you must upgrade to either:

- At least Git v2.24 (previously, the minimum required version was Git v2.22).
- The recommended Git v2.26.

Failure to do so will result in internal errors in the Gitaly service in some RPCs due
to the use of the new `--end-of-options` Git flag.

Additionally, in GitLab 13.1.0, the version of [Rails was upgraded from 6.0.3 to
6.0.3.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33454).
The Rails upgrade included a change to CSRF token generation which is
not backwards-compatible - GitLab servers with the new Rails version
will generate CSRF tokens that are not recognizable by GitLab servers
with the older Rails version - which could cause non-GET requests to
fail for [multi-node GitLab installations](https://docs.gitlab.com/omnibus/update/#multi-node--ha-deployment).

So, if you are using multiple Rails servers and specifically upgrading from 13.0,
all servers must first be upgraded to 13.1.X before upgrading to 13.2.0 or later:

1. Ensure all GitLab web nodes are on GitLab 13.1.X.
1. Optionally, enable the `global_csrf_token` feature flag to enable new
   method of CSRF token generation:

   ```ruby
   Feature.enable(:global_csrf_token)
   ```

1. Only then, continue to upgrade to later versions of GitLab.

### 12.2.0

In 12.2.0, we enabled Rails' authenticated cookie encryption. Old sessions are
automatically upgraded.

However, session cookie downgrades are not supported. So after upgrading to 12.2.0,
any downgrades would result to all sessions being invalidated and users are logged out.

### 12.0.0

In 12.0.0 we made various database related changes. These changes require that
users first upgrade to the latest 11.11 patch release. Once upgraded to 11.11.x,
users can upgrade to 12.0.x. Failure to do so may result in database migrations
not being applied, which could lead to application errors.

It is also required that you upgrade to 12.0.x before moving to a later version
of 12.x.

Example 1: you are currently using GitLab 11.11.8, which is the latest patch
release for 11.11.x. You can upgrade as usual to 12.0.x.

Example 2: you are currently using a version of GitLab 10.x. To upgrade, first
upgrade to the last 10.x release (10.8.7) then the last 11.x release (11.11.8).
Once upgraded to 11.11.8 you can safely upgrade to 12.0.x.

See our [documentation on upgrade paths](../policy/maintenance.md#upgrade-recommendations)
for more information.

## Miscellaneous

- [MySQL to PostgreSQL](mysql_to_postgresql.md) guides you through migrating
  your database from MySQL to PostgreSQL.
- [Restoring from backup after a failed upgrade](restore_after_failure.md)
- [Upgrading PostgreSQL Using Slony](upgrading_postgresql_using_slony.md), for
  upgrading a PostgreSQL database with minimal downtime.
- [Managing PostgreSQL extensions](../install/postgresql_extensions.md)
