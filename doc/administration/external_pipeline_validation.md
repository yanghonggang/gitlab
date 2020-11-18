---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference, howto
---

# External Pipeline Validation

You can use an external service for validating a pipeline before it's created.

CAUTION: **Warning:**
This is an experimental feature and subject to change without notice.

## Usage

GitLab sends a POST request to the external service URL with the pipeline
data as payload. GitLab then invalidates the pipeline based on the response
code. If there's an error or the request times out, the pipeline is not
invalidated.

Response Code Legend:

- `200` - Accepted
- `4xx` - Not Accepted
- Other Codes - Accepted and Logged

## Configuration

Set the `EXTERNAL_VALIDATION_SERVICE_URL` to the external service URL.

## Payload Schema

```json
{
  "type": "object",
  "required" : [
    "project",
    "user",
    "pipeline",
    "builds"
  ],
  "properties" : {
    "project": {
      "type": "object",
      "required": [
        "id",
        "path"
      ],
      "properties": {
        "id": { "type": "integer" },
        "path": { "type": "string" }
      }
    },
    "user": {
      "type": "object",
      "required": [
        "id",
        "username",
        "email"
      ],
      "properties": {
        "id": { "type": "integer" },
        "username": { "type": "string" },
        "email": { "type": "string" }
      }
    },
    "pipeline": {
      "type": "object",
      "required": [
        "sha",
        "ref",
        "type"
      ],
      "properties": {
        "sha": { "type": "string" },
        "ref": { "type": "string" },
        "type": { "type": "string" }
      }
    },
    "builds": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "name",
          "stage",
          "image",
          "services",
          "script"
        ],
        "properties": {
          "name": { "type": "string" },
          "stage": { "type": "string" },
          "image": { "type": ["string", "null"] },
          "services": {
            "type": ["array", "null"],
            "items": { "type": "string" }
          },
          "script": {
            "type": "array",
            "items": { "type": "string" }
          }
        }
      }
    }
  },
  "additionalProperties": false
}
```
