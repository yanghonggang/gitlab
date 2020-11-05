---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Environment selection

Some tests are designed to be run against specific environments or [pipelines](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#scheduled-qa-test-pipelines).
We can specify what environments or pipelines to run tests against using the `only` metadata.

## Available switches

| Switch | Function | Type |
| -------| ------- | ----- |
| `tld`  | Set the top-level domain matcher | `String` |
| `subdomain` | Set the subdomain matcher | `Array` or `String` |
| `domain` | Set the domain matcher | `String` |
| `production` | Match against production | `Static` |
| `pipeline` | Match against a pipeline | `Array` or `Static`|

CAUTION: **Caution:**
You cannot specify `:production` and `{ <switch>: 'value' }` simultaneously.
These options are mutually exclusive. If you want to specify production, you
can control the `tld` and `domain` independently.

## Examples

| Environment or pipeline                  | Key | Matches (regex for environments, string matching for pipelines)            |
| ----------------                         | --- | ---------------                                                            |
| `any`                                    | ``  | `.+.com`                                                                   |
| `gitlab.com`                             | `only: :production` | `gitlab.com`                                               |
| `staging.gitlab.com`                     | `only: { subdomain: :staging }` | `(staging).+.com`                              |
| `gitlab.com and staging.gitlab.com`      | `only: { subdomain: /(staging.)?/, domain: 'gitlab' }` | `(staging.)?gitlab.com` |
| `dev.gitlab.org`                         | `only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org` |
| `staging.gitlab.com & domain.gitlab.com` | `only: { subdomain: %i[staging domain] }` | `(staging|domain).+.com`             |
| `nightly`                                | `only: { pipeline: :nightly }` | "nightly" |
| `nightly`, `canary` | `only_run_in_pipeline: [:nightly, :canary]` | ["nightly"](https://gitlab.com/gitlab-org/quality/nightly) and ["canary"](https://gitlab.com/gitlab-org/quality/canary) |

```ruby
RSpec.describe 'Area' do
  it 'runs in any environment or pipeline' do; end

  it 'runs only in production environment', only: :production do; end

  it 'runs only in staging environment', only: { subdomain: :staging } do; end

  it 'runs in dev environment', only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' } do; end

  it 'runs in prod and staging environments', only: { subdomain: /(staging.)?/, domain: 'gitlab' } {}

  it 'runs only in nightly pipeline', only: { pipeline: :nightly } do; end

  it 'runs in nightly and canary pipelines', only: { pipeline: [:nightly, :canary] } do; end
end
```

If the test has a `before` or `after`, you must add the `only` metadata
to the outer `RSpec.describe`.

If you want to run an `only: { :pipeline }` tagged test on your local GDK make sure either the `CI_PROJECT_NAME` environment variable is unset, or that the `CI_PROJECT_NAME` environment variable matches the specified pipeline in the `only: { :pipeline }` tag, or just delete the `only: { :pipeline }` tag.

## Quarantining a test for a specific environment

Similarly to specifying that a test should only run against a specific environment, it's also possible to quarantine a
test only when it runs against a specific environment. The syntax is exactly the same, except that the `only: { ... }`
hash is nested in the [`quarantine: { ... }`](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests) hash.
For instance, `quarantine: { only: { subdomain: :staging } }` will only quarantine the test when run against staging.
