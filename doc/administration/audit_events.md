---
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Audit Events **(STARTER)**

GitLab offers a way to view the changes made within the GitLab server for owners and administrators on a [paid plan](https://about.gitlab.com/pricing/).

GitLab system administrators can also take advantage of the logs located on the
file system. See [the logs system documentation](logs.md) for more details.

You can generate an [Audit report](audit_reports.md) of audit events.

## Overview

**Audit Events** is a tool for GitLab owners and administrators
to track important events such as who performed certain actions and the
time they happened. For example, these actions could be a change to a user
permission level, who added a new user, or who removed a user.

## Use cases

- Check who changed the permission level of a particular
  user for a GitLab project.
- Track which users have access to a certain group of projects
  in GitLab, and who gave them that permission level.

## List of events

There are two kinds of events logged:

- Events scoped to the group or project, used by group and project managers
  to look up who made a change.
- Instance events scoped to the whole GitLab instance, used by your Compliance team to
  perform formal audits.

### Impersonation data **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/536) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.0.

Impersonation is where an administrator uses credentials to perform an action as a different user.

### Group events **(STARTER)**

NOTE: **Note:**
You need Owner [permissions](../user/permissions.md) to view the group Audit Events page.

To view a group's audit events, navigate to **Group > Settings > Audit Events**.
From there, you can see the following actions:

- Group name or path changed.
- Group repository size limit changed.
- Group created or deleted.
- Group changed visibility.
- User was added to group and with which [permissions](../user/permissions.md).
- User sign-in via [Group SAML](../user/group/saml_sso/index.md).
- Permissions changes of a user assigned to a group.
- Removed user from group.
- Project repository imported into group.
- [Project shared with group](../user/project/members/share_project_with_groups.md)
  and with which [permissions](../user/permissions.md).
- Removal of a previously shared group with a project.
- LFS enabled or disabled.
- Shared runners minutes limit changed.
- Membership lock enabled or disabled.
- Request access enabled or disabled.
- 2FA enforcement or grace period changed.
- Roles allowed to create project changed.
- Group CI/CD variable added, removed, or protected status changed. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30857) in GitLab 13.3.

Group events can also be accessed via the [Group Audit Events API](../api/audit_events.md#group-audit-events)

### Project events **(STARTER)**

NOTE: **Note:**
You need Maintainer [permissions](../user/permissions.md) or higher to view the project Audit Events page.

To view a project's audit events, navigate to **Project > Settings > Audit Events**.
From there, you can see the following actions:

- Added or removed deploy keys
- Project created, deleted, renamed, moved (transferred), changed path
- Project changed visibility level
- User was added to project and with which [permissions](../user/permissions.md)
- Permission changes of a user assigned to a project
- User was removed from project
- Project export was downloaded
- Project repository was downloaded
- Project was archived
- Project was unarchived
- Added, removed, or updated protected branches
- Release was added to a project
- Release was updated
- Release milestone associations changed
- Permission to approve merge requests by committers was updated ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9)
- Permission to approve merge requests by authors was updated ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9)
- Number of required approvals was updated ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7531) in GitLab 12.9)
- Added or removed users and groups from project approval groups ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213603) in GitLab 13.2)
- Project CI/CD variable added, removed, or protected status changed ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30857) in GitLab 13.4)
- User was approved via Admin Area ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276250) in GitLab 13.6)

Project events can also be accessed via the [Project Audit Events API](../api/audit_events.md#project-audit-events).

### Instance events **(PREMIUM ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2336) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.3.

Server-wide audit logging introduces the ability to observe user actions across
the entire instance of your GitLab server, making it easy to understand who
changed what and when for audit purposes.

To view the server-wide administrator log, visit **Admin Area > Monitoring > Audit Log**.

In addition to the group and project events, the following user actions are also
recorded:

- Sign-in events and the authentication type (such as standard, LDAP, or OmniAuth)
- Failed sign-ins
- Added SSH key
- Added or removed email
- Changed password
- Ask for password reset
- Grant OAuth access
- Started or stopped user impersonation
- Changed username ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7797) in GitLab 12.8)
- User was deleted ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/251) in GitLab 12.8)
- User was added ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/251) in GitLab 12.8)
- User was blocked via Admin Area ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/251) in GitLab 12.8)
- User was blocked via API ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25872) in GitLab 12.9)
- Failed second-factor authentication attempt ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16826) in GitLab 13.5)
- A user's personal access token was successfully created or revoked ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276921) in GitLab 13.6)
- A failed attempt to create or revoke a user's personal access token ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276921) in GitLab 13.6)

It's possible to filter particular actions by choosing an audit data type from
the filter dropdown box. You can further filter by specific group, project, or user
(for authentication events).

![audit log](img/audit_log.png)

Instance events can also be accessed via the [Instance Audit Events API](../api/audit_events.md#instance-audit-events).

### Missing events

Some events are not tracked in Audit Events. See the following
epics for more detail on which events are not being tracked, and our progress
on adding these events into GitLab:

- [Project settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/474)
- [Group settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/475)
- [Instance-level settings and activity](https://gitlab.com/groups/gitlab-org/-/epics/476)

### Disabled events

#### Repository push

The current architecture of audit events is not prepared to receive a very high amount of records.
It may make the user interface for your project or audit logs very busy, and the disk space consumed by the
`audit_events` PostgreSQL table may increase considerably. It's disabled by default
to prevent performance degradations on GitLab instances with very high Git write traffic.

In an upcoming release, Audit Logs for Git push events will be enabled
by default. Follow [#7865](https://gitlab.com/gitlab-org/gitlab/-/issues/7865) for updates.

If you still wish to enable **Repository push** events in your instance, follow
the steps bellow.

**In Omnibus installations:**

1. Enter the Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Flip the switch and enable the feature flag:

   ```ruby
   Feature.enable(:repository_push_audit_event)
   ```

## Retention policy

On GitLab.com, Audit Event records become subject to deletion after 400 days, or when your license is downgraded to a tier that does not include access to Audit Events. Data that is subject to deletion will be deleted at GitLab's discretion, possibly without additional notice.

If you require a longer retention period, you should independently archive your Audit Event data, which you can retrieve through the [Audit Events API](../api/audit_events.md).

## Export to CSV **(PREMIUM ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1449) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.4.
> - It's [deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-audit-log-export-to-csv). **(PREMIUM ONLY)**

CAUTION: **Warning:**
This feature might not be available to you. Check the **version history** note above for details.
If available, you can enable it with a [feature flag](#enable-or-disable-audit-log-export-to-csv).

Export to CSV allows customers to export the current filter view of your audit log as a
CSV file,
which stores tabular data in plain text. The data provides a comprehensive view with respect to
audit events.

To export the Audit Log to CSV, navigate to
**{monitor}** **Admin Area > Monitoring > Audit Log**

1. Click in the field **Search**.
1. In the dropdown menu that appears, select the event type that you want to filter by.
1. Select the preferred date range.
1. Click **Export as CSV**.

![Export Audit Log](img/export_audit_log_v13_4.png)

### Sort

Exported events are always sorted by `ID` in ascending order.

### Format

Data is encoded with a comma as the column delimiter, with `"` used to quote fields if needed, and newlines to separate rows.
The first row contains the headers, which are listed in the following table along with a description of the values:

| Column  | Description |
|---------|-------------|
| ID | Audit event `id` |
| Author ID | ID of the author |
| Author Name | Full name of the author |
| Entity ID | ID of the scope |
| Entity Type | Type of the entity (`Project`/`Group`/`User`) |
| Entity Path | Path of the entity |
| Target ID | ID of the target |
| Target Type | Type of the target |
| Target Details | Details of the target |
| Action | Description of the action |
| IP Address | IP address of the author who performed the action |
| Created At (UTC) | Formatted as `YYYY-MM-DD HH:MM:SS` |

### Limitation

The Audit Log CSV file size is limited to a maximum of `100,000` events.
The remaining records are truncated when this limit is reached.

### Enable or disable Audit Log Export to CSV

The Audit Log Export to CSV is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:audit_log_export_csv)
```

To disable it:

```ruby
Feature.disable(:audit_log_export_csv)
```
