---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Pipeline artifacts

Pipeline artifacts are files created by GitLab after a pipeline finishes. These are different than [job artifacts](job_artifacts.md) because they are not explicitly managed by the `.gitlab-ci.yml` definitions.

Pipeline artifacts are used by the [test coverage visualization feature](../../user/project/merge_requests/test_coverage_visualization.md) to collect coverage information. It uses the [`artifacts: reports`](../yaml/README.md#artifactsreports) CI/CD keyword.

## Storage

Pipeline artifacts are saved to disk or object storage. They count towards a project's [storage usage quota](../../user/group/index.md#storage-usage-quota). The **Artifacts** on the usage quote page is the sum of all job artifacts and pipeline artifacts.

Pipeline artifacts are erased after one week.
