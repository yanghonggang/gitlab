---
type: reference, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Groups

With GitLab Groups, you can:

- Assemble related projects together.
- Grant members access to several projects at once.

For a video introduction to GitLab Groups, see [GitLab University: Repositories, Projects and Groups](https://www.youtube.com/watch?v=4TWfh1aKHHw).

Groups can also be nested in [subgroups](subgroups/index.md).

Find your groups by clicking **Groups > Your Groups** in the top navigation.

![GitLab Groups](img/groups.png)

> The **Groups** dropdown in the top navigation was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/36234) in [GitLab 11.1](https://about.gitlab.com/releases/2018/07/22/gitlab-11-1-released/#groups-dropdown-in-navigation).

The **Groups** page displays:

- All groups you are a member of, when **Your groups** is selected.
- A list of public groups, when **Explore public groups** is selected.

Each group on the **Groups** page is listed with:

- How many subgroups it has.
- How many projects it contains.
- How many members the group has, not including members inherited from parent group(s).
- The group's visibility.
- A link to the group's settings, if you have sufficient permissions.
- A link to leave the group, if you are a member.

## Use cases

You can create groups for numerous reasons. To name a couple:

- Grant access to multiple projects and multiple team members in fewer steps by organizing related projects under the same [namespace](#namespaces) and adding members to the top-level group.
- Make it easier to `@mention` all of your team at once in issues and merge requests by creating a group and including the appropriate members.

For example, you could create a group for your company members, and create a [subgroup](subgroups/index.md) for each individual team. Let's say you create a group called `company-team`, and you create subgroups in this group for the individual teams `backend-team`, `frontend-team`, and `production-team`.

- When you start a new implementation from an issue, you add a comment:
  _"`@company-team`, let's do it! `@company-team/backend-team` you're good to go!"_
- When your backend team needs help from frontend, they add a comment:
  _"`@company-team/frontend-team` could you help us here please?"_
- When the frontend team completes their implementation, they comment:
  _"`@company-team/backend-team`, it's done! Let's ship it `@company-team/production-team`!"_

## Namespaces

In GitLab, a namespace is a unique name to be used as a user name, a group name, or a subgroup name.

- `http://gitlab.example.com/username`
- `http://gitlab.example.com/groupname`
- `http://gitlab.example.com/groupname/subgroup_name`

For example, consider a user named Alex:

1. Alex creates an account on GitLab.com with the username `alex`;
   their profile will be accessed under `https://gitlab.example.com/alex`
1. Alex creates a group for their team with the group name `alex-team`;
   the group and its projects will be accessed under `https://gitlab.example.com/alex-team`
1. Alex creates a subgroup of `alex-team` with the subgroup name `marketing`;
   this subgroup and its projects will be accessed under `https://gitlab.example.com/alex-team/marketing`

By doing so:

- Any team member mentions Alex with `@alex`
- Alex mentions everyone from their team with `@alex-team`
- Alex mentions only the marketing team with `@alex-team/marketing`

## Issues and merge requests within a group

Issues and merge requests are part of projects. For a given group, you can view all of the
[issues](../project/issues/index.md#issues-list) and [merge requests](../project/merge_requests/reviewing_and_managing_merge_requests.md#view-merge-requests-for-all-projects-in-a-group) across all projects in that group,
together in a single list view.

### Bulk editing issues and merge requests

For details, see [bulk editing issues and merge requests](../group/bulk_editing/index.md).

## Create a new group

> For a list of words that are not allowed to be used as group names see the
> [reserved names](../reserved_names.md).

To create a new Group, either:

- In the top menu, click **Groups** and then **Your Groups**, and click the green button **New group**.

  ![new group from groups page](img/new_group_from_groups.png)

- Or, in the top menu, expand the `plus` sign and choose **New group**.

  ![new group from elsewhere](img/new_group_from_other_pages.png)

Add the following information:

![new group information](img/create_new_group_info.png)

1. The **Group name** will automatically populate the URL. Optionally, you can change it.
   This is the name that displays in group views.
   The name can contain only:
   - Alphanumeric characters
   - Underscores
   - Dashes and dots
   - Spaces
1. The **Group URL** is the namespace under which your projects will be hosted.
   The URL can contain only:
   - Alphanumeric characters
   - Underscores
   - Dashes and dots (it cannot start with dashes or end in a dot)
1. Optionally, you can add a brief description to tell others
   what this group is about.
1. Optionally, choose an avatar for your group.
1. Choose the [visibility level](../../public_access/public_access.md).

For more details on creating groups, watch the video [GitLab Namespaces (users, groups and subgroups)](https://youtu.be/r0sJgjR2f5A).

## Add users to a group

A benefit of putting multiple projects in one group is that you can
give a user access to all projects in the group with one action.

Add members to a group by navigating to the group's dashboard and clicking **Members**.

![add members to group](img/add_new_members_v13_6.png)

Select the [permission level](../permissions.md#permissions), and add the new member. You can also set the expiring date for that user; this is the date on which they will no longer have access to your group.

Consider a group with two projects:

- On the **Group Members** page, you can now add a new user to the group.
- Now, because this user is a **Developer** member of the group, they automatically
  get **Developer** access to **all projects** within that group.

To increase the access level of an existing user for a specific project,
add them again as a new member to the project with the desired permission level.

## Request access to a group

As a group owner, you can enable or disable the ability for non-members to request access to
your group. Go to the group settings, and click **Allow users to request access**.

As a user, you can request to be a member of a group, if that setting is enabled. Go to the group for which you'd like to be a member, and click the **Request Access** button on the right
side of your screen.

![Request access button](img/request_access_button.png)

Once access is requested:

- Up to ten group owners are notified of your request via email.
  Email is sent to the most recently active group owners.
- Any group owner can approve or decline your request on the members page.

![Manage access requests](img/access_requests_management.png)

If you change your mind before your request is approved, just click the
**Withdraw Access Request** button.

![Withdraw access request button](img/withdraw_access_request_button.png)

## Changing the owner of a group

Ownership of a group means at least one of its members has
[Owner permission](../permissions.md#group-members-permissions). Groups must have at
least one owner.

Changing the owner of a group with only one owner is possible. To change the sole owner
of a group:

- As an administrator:
  1. Go to the group's **{users}** **Members** tab.
  1. Give a different member **Owner** permissions.
  1. Refresh the page. You can now remove **Owner** permissions from the original owner.
- As the current group's owner:
  1. Go to the group's **{users}** **Members** tab.
  1. Give a different member **Owner** permissions.
  1. Have the new owner sign in and remove **Owner** permissions from you.

## Remove a member from the group

Only users with permissions of [Owner](../permissions.md#group-members-permissions) can manage
group members.

You can remove a member from the group if the given member has a direct membership in the group. If
membership is inherited from a parent group, then the member can be removed only from the parent
group itself.

When removing a member, you can decide whether to unassign the user from all issues and merge
requests they are currently assigned or leave the assignments as they are.

- **Unassigning the removed member** from all issues and merge requests might be helpful when a user
  is leaving a private group and you wish to revoke their access to any issues and merge requests
  they are assigned.
- **Keeping the issues and merge requests assigned** might be helpful for groups that accept public
  contributions where a user doesn't have to be a member to be able to contribute to issues and
  merge requests.

To remove a member from a group:

1. In a group, go to **{users}** **Members**.
1. Click the **Delete** **{remove}** button next to a group member you want to remove.
   A **Remove member** modal appears.
1. (Optional) Select the **Also unassign this user from related issues and merge requests** checkbox.
1. Click **Remove member**.

## Changing the default branch protection of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7583) in GitLab 12.9.

By default, every group inherits the branch protection set at the global level.

To change this setting for a specific group:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section.
1. Select the desired option in the **Default branch protection** dropdown list.
1. Click **Save changes**.

To change this setting globally, see [Default branch protection](../admin_area/settings/visibility_and_access_controls.md#default-branch-protection).

NOTE: **Note:**
In [GitLab Premium or higher](https://about.gitlab.com/pricing/), GitLab administrators can choose to [disable group owners from updating the default branch protection](../admin_area/settings/visibility_and_access_controls.md#disable-group-owners-from-updating-default-branch-protection).

## Add projects to a group

There are two different ways to add a new project to a group:

- Select a group, and then click **New project**. You can then continue [creating your project](../../gitlab-basics/create-project.md).

  ![New project](img/create_new_project_from_group_v13_6.png)

- While you are creating a project, select a group namespace
  you've already created from the dropdown menu.

  ![Select group](img/select_group_dropdown.png)

### Default project-creation level

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2534) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.5.
> - Brought to [GitLab Starter](https://about.gitlab.com/pricing/) in 10.7.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25975) to [GitLab Core](https://about.gitlab.com/pricing/) in 11.10.

By default, [Developers and Maintainers](../permissions.md#group-members-permissions) can create projects under a group.

To change this setting for a specific group:

1. Go to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section.
1. Select the desired option in the **Allowed to create projects** dropdown list.
1. Click **Save changes**.

To change this setting globally, see [Default project creation protection](../admin_area/settings/visibility_and_access_controls.md#default-project-creation-protection).

## View group details

A group's **Details** page includes tabs for:

- Subgroups and projects.
- Shared projects.
- Archived projects.

### Group activity analytics overview

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207164) in GitLab [Starter](https://about.gitlab.com/pricing/) 12.10 as
a [beta feature](https://about.gitlab.com/handbook/product/#beta)

The group details view also shows the number of the following items created in the last 90 days: **(STARTER)**

- Merge requests.
- Issues.
- Members.

These Group Activity Analytics can be enabled with the `group_activity_analytics` [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-locally-in-development).

![Recent Group Activity](img/group_activity_analytics_v12_10.png)

For details, see the section on how you can [View group activity](#view-group-activity).

## View group activity

A group's **Activity** page displays the most recent actions taken in a group, including:

- **Push events**: Recent pushes to branches.
- **Merge events**: Recent merges.
- **Issue events**: Issues opened or closed.
- **Epic events**: Epics opened or closed.
- **Comments**: Comments opened or closed.
- **Team**: Team members who have joined or left the group.
- **Wiki**: Wikis created, deleted, or updated.

The entire activity feed is also available in Atom format by clicking the
**RSS** icon.

To view a group's **Activity** page:

1. Go to the group's page.
1. In the left navigation menu, go to **Group Overview** and select **Activity**.

## Transfer projects into groups

Learn how to [transfer a project into a group](../project/settings/index.md#transferring-an-existing-project-into-another-namespace).

## Sharing a project with a group

You can [share your projects with a group](../project/members/share_project_with_groups.md)
and give all group members access to the project at once.

Alternatively, you can [lock the sharing with group feature](#share-with-group-lock).

## Sharing a group with another group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18328) in GitLab 12.7.

Similarly to [sharing a project with a group](#sharing-a-project-with-a-group),
you can share a group with another group to give direct group members access
to the shared group. This is not valid for inherited members.

To share a given group, for example, 'Frontend' with another group, for example,
'Engineering':

1. Navigate to your 'Frontend' group page and use the left navigation menu to go
   to your group **Members**.
1. Select the **Invite group** tab.
1. Add 'Engineering' with the maximum access level of your choice.
1. Click **Invite**.

All the members of the 'Engineering' group will have been added to 'Frontend'.

## Manage group memberships via LDAP **(STARTER ONLY)**

Group syncing allows LDAP groups to be mapped to GitLab groups. This provides more control over per-group user management. To configure group syncing edit the `group_base` **DN** (`'OU=Global Groups,OU=GitLab INT,DC=GitLab,DC=org'`). This **OU** contains all groups that will be associated with GitLab groups.

Group links can be created using either a CN or a filter. These group links are created on the **Group Settings -> LDAP Synchronization** page. After configuring the link, it may take over an hour for the users to sync with the GitLab group.

For more information on the administration of LDAP and group sync, refer to the [main LDAP documentation](../../administration/auth/ldap/index.md#group-sync).

NOTE: **Note:**
If an LDAP user is a group member when LDAP Synchronization is added, and they are not part of the LDAP group, they will be removed from the group.

### Creating group links via CN **(STARTER ONLY)**

To create group links via CN:

1. Select the **LDAP Server** for the link.
1. Select `LDAP Group cn` as the **Sync method**.
1. In the **LDAP Group cn** text input box, begin typing the CN of the group. There will be a dropdown menu with matching CNs within the configured `group_base`. Select your CN from this list.
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Click the `Add Synchronization` button to save this group link.

![Creating group links via CN](img/ldap_sync_cn_v13_1.png)

### Creating group links via filter **(PREMIUM ONLY)**

To create group links via filter:

1. Select the **LDAP Server** for the link.
1. Select `LDAP user filter` as the **Sync method**.
1. Input your filter in the **LDAP User filter** box. Follow the [documentation on user filters](../../administration/auth/ldap/index.md#set-up-ldap-user-filter).
1. In the **LDAP Access** section, select the [permission level](../permissions.md) for users synced in this group.
1. Click the `Add Synchronization` button to save this group link.

![Creating group links via filter](img/ldap_sync_filter_v13_1.png)

### Overriding user permissions **(STARTER ONLY)**

In GitLab [8.15](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/822) and later, LDAP user permissions can now be manually overridden by an admin user. To override a user's permissions:

1. Go to your group's **Members** page.
1. Select the pencil icon in the row for the user you are editing.
1. Select the brown `Edit permissions` button in the modal.

![Setting manual permissions](img/manual_permissions_v13_6.png)

Now you will be able to edit the user's permissions from the **Members** page.

## Epics **(ULTIMATE)**

> Introduced in [GitLab Ultimate](https://about.gitlab.com/pricing/) 10.2.

Epics let you manage your portfolio of projects more efficiently and with less
effort by tracking groups of issues that share a theme, across projects and
milestones.

[Learn more about Epics.](epics/index.md)

## Group wikis **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13195) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.5.

Group wikis work the same way as [project wikis](../project/wiki/index.md), please refer to those docs for details on usage.

Group wikis can be edited by members with [Developer permissions](../../user/permissions.md#group-members-permissions)
and above.

### Group wikis limitations

There are a few limitations compared to project wikis:

- Local Git access is not supported yet.
- Group wikis are not included in global search, group exports, backups, and Geo replication.
- Changes to group wikis don't show up in the group's activity feed.
- Group wikis [can't be moved](../../api/project_repository_storage_moves.md#limitations) using the project
  repository moves API.

For updates, you can follow:

- [The epic tracking feature parity with project wikis](https://gitlab.com/groups/gitlab-org/-/epics/2782).
- [The issue for adding the ability to move group wikis using the API](https://gitlab.com/gitlab-org/gitlab/-/issues/219003).

## Group Security Dashboard **(ULTIMATE)**

Get an overview of the vulnerabilities of all the projects in a group and its subgroups.

[Learn more about the Group Security Dashboard.](../application_security/security_dashboard/index.md)

## Insights **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/725) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.0.

Configure the Insights that matter for your groups or projects, allowing users
to explore data such as:

- Triage hygiene
- Issues created/closed per a given period
- Average time for merge requests to be merged
- Much more

[Learn more about Insights](insights/index.md).

## Transferring groups

From GitLab 10.5, you can transfer groups in the following ways:

- Transfer a subgroup to a new parent group.
- Convert a top-level group into a subgroup by transferring it to the desired group.
- Convert a subgroup into a top-level group by transferring it out of its current group.

When transferring groups, note:

- Changing a group's parent can have unintended side effects. See [Redirects when changing repository paths](../project/index.md#redirects-when-changing-repository-paths).
- You can only transfer groups to groups you manage.
- You must update your local repositories to point to the new location.
- If the immediate parent group's visibility is lower than the group's current visibility, visibility levels for subgroups and projects will change to match the new parent group's visibility.
- Only explicit group membership is transferred, not inherited membership. If the group's owners have only inherited membership, this leaves the group without an owner. In this case, the user transferring the group becomes the group's owner.
- Transfers will fail if [packages](../packages/index.md) exist in any of the projects within the group, or in any of its subgroups.

## Group settings

After creating a group, you can manage its settings by navigating to
the group's dashboard, and clicking **Settings**.

![group settings](img/group_settings.png)

### General settings

In addition to editing any settings you previously
set when [creating the group](#create-a-new-group), you can also
access further configurations for your group.

#### Changing a group's path

Changing a group's path (group URL) can have unintended side effects. Read
[how redirects will behave](../project/index.md#redirects-when-changing-repository-paths)
before proceeding.

If you are vacating the path so it can be claimed by another group or user,
you may need to rename the group too, since both names and paths must
be unique.

To change your group path (group URL):

1. Navigate to your group's **Settings > General** page.
1. Expand the **Path, transfer, remove** section.
1. Enter a new name under **Change group URL**.
1. Click **Change group URL**.

CAUTION: **Caution:**
It is currently not possible to rename a namespace if it contains a
project with [Container Registry](../packages/container_registry/index.md) tags,
because the project cannot be moved.

TIP: **Tip:**
If you want to retain ownership over the original namespace and
protect the URL redirects, then instead of changing a group's path or renaming a
username, you can create a new group and transfer projects to it.

### Group repository settings

You can change settings that are specific to repositories in your group.

#### Custom initial branch name **(CORE ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43290) in GitLab 13.6.

By default, when you create a new project in GitLab, the initial branch is called `master`.
For groups, a group administrator can customize the initial branch name to something
else. This way, every new project created under that group from then on will start from the custom branch name rather than `master`. To do so:

1. Go to the **Group page > Settings > Repository** and expand **Default initial
   branch name**.
1. Change the default initial branch to a custom name of your choice.
1. **Save Changes**.

### Remove a group

To remove a group and its contents:

1. Navigate to your group's **Settings > General** page.
1. Expand the **Path, transfer, remove** section.
1. In the Remove group section, click the **Remove group** button.
1. Confirm the action when asked to.

This action either:

- Removes the group, and also queues a background job to delete all projects in that group.
- Since [GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/issues/33257), on [Premium or Silver](https://about.gitlab.com/pricing/premium/) or higher tiers, this action adds a background job to mark a group for deletion. By default, the job schedules the deletion 7 days in the future. You can modify this waiting period through the [instance settings](../admin_area/settings/visibility_and_access_controls.md#default-deletion-delay).

Since [GitLab 13.6](https://gitlab.com/gitlab-org/gitlab/-/issues/39504), if the user who sets up the deletion leaves or is otherwise removed from the group before the
actual deletion happens, the job is cancelled, and the group is no longer scheduled for deletion.

### Restore a group **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

To restore a group that is marked for deletion:

1. Navigate to your group's **Settings > General** page.
1. Expand the **Path, transfer, remove** section.
1. In the Restore group section, click the **Restore group** button.

#### Enforce 2FA to group members

Add a security layer to your group by
[enforcing two-factor authentication (2FA)](../../security/two_factor_authentication.md#enforcing-2fa-for-all-users-in-a-group)
for all group members.

#### Share with group lock

Prevent projects in a group from [sharing
a project with another group](../project/members/share_project_with_groups.md) to enable tighter control over project access.

For example, let's say you have two distinct teams (Group A and Group B) working together in a project, and to inherit the group membership, you share the project between the
two groups A and B. **Share with group lock** prevents any project within
the group from being shared with another group,
guaranteeing that only the right group members have access to those projects.

To enable this feature, navigate to the group settings page. Select
**Share with group lock** and **Save the group**.

![Checkbox for share with group lock](img/share_with_group_lock.png)

#### Member Lock **(STARTER)**

Member lock lets a group owner prevent any new project membership to all of the
projects within a group, allowing tighter control over project membership.

For example, if you want to lock the group for an [Audit Event](../../administration/audit_events.md),
enable Member lock to guarantee that project membership cannot be modified during that audit.

To enable this feature:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and select **Member lock**.
1. Click **Save changes**.

![Checkbox for membership lock](img/member_lock.png)

This will disable the option for all users who previously had permissions to
operate project memberships, so no new users can be added. Furthermore, any
request to add a new user to a project through API will not be possible.

#### IP access restriction **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1985) in [GitLab Ultimate and Gold](https://about.gitlab.com/pricing/) 12.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/215410) to [GitLab Premium and Silver](https://about.gitlab.com/pricing/) in 13.1.

To make sure only people from within your organization can access particular
resources, you have the option to restrict access to groups and their
underlying projects, issues, etc, by IP address. This can help ensure that
particular content doesn't leave the premises, while not blocking off access to
the entire instance.

Add one or more allowed IP subnets using CIDR notation to the group settings and anyone
coming from a different IP address won't be able to access the restricted
content.

Restriction currently applies to:

- UI.
- [From GitLab 12.3](https://gitlab.com/gitlab-org/gitlab/-/issues/12874), API access.
- [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/32113), Git actions via SSH.

To avoid accidental lock-out, admins and group owners are able to access
the group regardless of the IP restriction.

To enable this feature:

1. Navigate to the group’s **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and enter IP address ranges into **Allow access to the following IP addresses** field.
1. Click **Save changes**.

![Domain restriction by IP address](img/restrict-by-ip.gif)

#### Allowed domain restriction **(PREMIUM)**

>- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7297) in [GitLab Premium and Silver](https://about.gitlab.com/pricing/) 12.2.
>- Support for specifying multiple email domains [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33143) in GitLab 13.1

You can restrict access to groups by allowing only users with email addresses in particular domains to be added to the group.

Add email domains you want to allow and users with emails from different domains won't be allowed to be added to this group.

Some domains cannot be restricted. These are the most popular public email domains, such as:

- `gmail.com`
- `yahoo.com`
- `hotmail.com`
- `aol.com`
- `msn.com`
- `hotmail.co.uk`
- `hotmail.fr`
- `live.com`
- `outlook.com`
- `icloud.com`

To enable this feature:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and enter the domain names into **Restrict membership by email** field.
1. Click **Save changes**.

![Domain restriction by email](img/restrict-by-email.gif)

This will enable the domain-checking for all new users added to the group from this moment on.

#### Group file templates **(PREMIUM)**

Group file templates allow you to share a set of templates for common file
types with every project in a group. It is analogous to the
[instance template repository](../admin_area/settings/instance_template_repository.md)
feature, and the selected project should follow the same naming conventions as
are documented on that page.

You can only choose projects in the group as the template source.
This includes projects shared with the group, but it **excludes** projects in
subgroups or parent groups of the group being configured.

You can configure this feature for both subgroups and immediate parent groups. A project
in a subgroup will have access to the templates for that subgroup, as well as
any immediate parent groups.

![Group file template dropdown](img/group_file_template_dropdown.png)

To enable this feature, navigate to the group settings page, expand the
**Templates** section, choose a project to act as the template repository, and
**Save group**.

![Group file template settings](img/group_file_template_settings.png)

#### Group-level project templates **(PREMIUM)**

Define project templates at a group level by setting a group as the template source.
[Learn more about group-level project templates](custom_project_templates.md).

#### Disabling email notifications

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23585) in GitLab 12.2.

You can disable all email notifications related to the group, which includes its subgroups and projects.

To enable this feature:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and select **Disable email notifications**.
1. Click **Save changes**.

#### Disabling group mentions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21301) in GitLab 12.6.

You can prevent users from being added to a conversation and getting notified when
anyone mentions a group in which those users are members.

Groups with disabled mentions are visualized accordingly in the autocompletion dropdown.

This is particularly helpful for groups with a large number of users.

To enable this feature:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and select **Disable group mentions**.
1. Click **Save changes**.

#### Enabling delayed Project removal **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.

By default, projects within a group are deleted immediately.
Optionally, on [Premium or Silver](https://about.gitlab.com/pricing/) or higher tiers,
you can configure the projects within a group to be deleted after a delayed interval.

During this interval period, the projects will be in a read-only state and can be restored, if required.
The interval period defaults to 7 days, and can be modified by an admin in the [instance settings](../admin_area/settings/visibility_and_access_controls.md#default-deletion-delay).

To enable delayed deletion of projects:

1. Navigate to the group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and check **Enable delayed project removal**.
1. Click **Save changes**.

NOTE: **Note:**
The group setting for delayed deletion is not inherited by sub-groups and has to be individually defined for each group.

#### Prevent project forking outside group **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/216987) in GitLab 13.3.

By default, projects within a group can be forked.
Optionally, on [Premium or Silver](https://about.gitlab.com/pricing/) or higher tiers,
you can prevent the projects within a group from being forked outside of the current top-level group.

Previously this setting was available only for groups enforcing group managed account. This setting will be
removed from SAML setting page and migrated to group setting, but in the interim period of changes both of those settings will be taken into consideration, if even one is set to `true` then it will be assumed group does not allow forking projects outside.

To enable prevent project forking:

1. Navigate to the top-level group's **Settings > General** page.
1. Expand the **Permissions, LFS, 2FA** section, and check **Prevent project forking outside current group**.
1. Click **Save changes**.

### Advanced settings

- **Projects**: View all projects within that group, add members to each project,
  access each project's settings, and remove any project, all from the same screen.
- **Webhooks**: Configure [webhooks](../project/integrations/webhooks.md) for your group.
- **Kubernetes cluster integration**: Connect your GitLab group with [Kubernetes clusters](clusters/index.md).
- **Audit Events**: View [Audit Events](../../administration/audit_events.md)
  for the group. **(STARTER ONLY)**
- **Pipelines quota**: Keep track of the [pipeline quota](../admin_area/settings/continuous_integration.md) for the group.
- **Integrations**: Configure [integrations](../admin_area/settings/project_integration_management.md) for your group.

#### Storage usage quota **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/13294) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.0.

A group owner can check the aggregated storage usage for all the projects in a group, sub-groups included, in the **Storage** tab of the **Usage Quotas** page available to the group page settings list.

![Group storage usage quota](img/group_storage_usage_quota.png)

The total usage of the storage is updated if any relevant event that
will affect its value is triggered (e.g., a commit push).
For performance reasons, we may delay the update up to 1 hour and 30 minutes.

If your namespace shows `N/A` as the total storage usage, you can trigger a recalculation by pushing a commit to any project in that namespace.

#### Group push rules **(STARTER)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34370) in [GitLab Starter](https://about.gitlab.com/pricing/) 12.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/224129) in GitLab 13.4.

Group push rules allow group maintainers to set
[push rules](../../push_rules/push_rules.md) for newly created projects within the specific group.

To configure push rules for a group, navigate to **{push-rules}** on the group's
sidebar.

When set, new subgroups have push rules set for them based on either:

- The closest parent group with push rules defined.
- Push rules set at the instance level, if no parent groups have push rules defined.

### Maximum artifacts size **(CORE ONLY)**

For information about setting a maximum artifact size for a group, see
[Maximum artifacts size](../admin_area/settings/continuous_integration.md#maximum-artifacts-size).

## User contribution analysis **(STARTER)**

With [GitLab Contribution Analytics](contribution_analytics/index.md),
you have an overview of the contributions (pushes, merge requests,
and issues) performed by your group members.

## Issue analytics **(PREMIUM)**

With [GitLab Issue Analytics](issues_analytics/index.md), you can see a bar chart of the number of issues created each month in your groups.

## Repositories analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/215104) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.4.

With [GitLab Repositories Analytics](repositories_analytics/index.md), you can download a CSV of the latest coverage data for all the projects in your group.

## Dependency Proxy

Use GitLab as a [dependency proxy](../packages/dependency_proxy/index.md) for upstream Docker images.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
