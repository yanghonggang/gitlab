---
stage: Growth
group: Expansion
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Invitations API

Use the Invitations API to send email to users you want to join a group or project, and to list pending
invitations.

## Valid access levels

To send an invitation, you must have access to the project or group you are sending email for. Valid access
levels are defined in the `Gitlab::Access` module. Currently, these levels are valid:

- No access (`0`)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`) - Only valid to set for groups

CAUTION: **Caution:**
Due to [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219299),
projects in personal namespaces will not show owner (`50`) permission.

## Invite by email to group or project

Invites a new user by email to join a group or project.

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `email` | integer/string | yes | The email of the new member or multiple emails separated by commas |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "email=test@example.com&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/invitations"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "email=test@example.com&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/invitations"
```

Example responses:

When all emails were successfully sent:

```json
{  "status":  "success"  }
```

When there was any error sending the email:

```json
{
  "status": "error",
  "message": {
               "test@example.com": "Already invited",
               "test2@example.com": "Member already exsists"
             }
}
```

## List all invitations pending for a group or project

Gets a list of invited group or project members viewable by the authenticated user.
Returns invitations to direct members only, and not through inherited ancestors' groups.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `page`    | integer | no   | Page to retrieve                      |
| `per_page`| integer | no   | Number of member invitations to return per page |
| `query`   | string  | no   | A query string to search for invited members by invite email. Query text must match email address exactly. When empty, returns all invitations. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/invitations?query=member@example.org"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/invitations?query=member@example.org"
```

Example response:

```json
 [
   {
     "id": 1,
     "invite_email": "member@example.org",
     "invited_at": "2020-10-22T14:13:35Z",
     "access_level": 30,
     "expires_at": "2020-11-22T14:13:35Z",
     "user_name": "Raymond Smith",
     "created_by_name": "Administrator"
   },
]
```
