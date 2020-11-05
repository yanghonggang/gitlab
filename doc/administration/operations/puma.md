---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Switching to Puma

As of GitLab 12.9, [Puma](https://github.com/puma/puma) has replaced [Unicorn](https://yhbt.net/unicorn/)
as the default web server. From GitLab 13.0, the following run Puma instead of Unicorn unless
explicitly configured not to:

- All-in-one package-based installations.
- Helm chart-based installations.

## Why switch to Puma?

Puma has a multi-thread architecture which uses less memory than a multi-process
application server like Unicorn. On GitLab.com, we saw a 40% reduction in memory
consumption.

Most Rails applications requests normally include a proportion of I/O wait time.
During I/O wait time MRI Ruby will release the GVL (Global VM Lock) to other threads.
Multi-threaded Puma can therefore still serve more requests than a single process.

## Configuring Puma to replace Unicorn

Beginning with GitLab 13.0, Puma is the default application server. We plan to remove support for
Unicorn in GitLab 14.0.

When switching to Puma, Unicorn server configuration
will _not_ carry over automatically, due to differences between the two application servers. For Omnibus-based
deployments, see [Configuring Puma Settings](https://docs.gitlab.com/omnibus/settings/puma.html#configuring-puma-settings).
For Helm based deployments, see the [Webservice Chart documentation](https://docs.gitlab.com/charts/charts/gitlab/webservice/index.html).

Additionally we strongly recommend that multi-node deployments [configure their load balancers to utilize the readiness check](../load_balancer.md#readiness-check) due to a difference between Unicorn and Puma in how they handle connections during a restart of the service.

## Performance caveat when using Puma with Rugged

For deployments where NFS is used to store Git repository, we allow GitLab to use
[direct Git access](../gitaly/index.md#direct-access-to-git-in-gitlab) to improve performance using
[Rugged](https://github.com/libgit2/rugged).

Rugged usage is automatically enabled if direct Git access
[is available](../gitaly/index.md#how-it-works)
and Puma is running single threaded, unless it is disabled by
[feature flags](../../development/gitaly.md#legacy-rugged-code).

MRI Ruby uses a GVL. This allows MRI Ruby to be multi-threaded, but running at
most on a single core. Since Rugged can use a thread for long periods of
time (due to intensive I/O operations of Git access), this can starve other threads
that might be processing requests. This is not a case for Unicorn or Puma running
in a single thread mode, as concurrently at most one request is being processed.

We are actively working on removing Rugged usage. Even though performance without Rugged
is acceptable today, in some cases it might be still beneficial to run with it.

Given the caveat of running Rugged with multi-threaded Puma, and acceptable
performance of Gitaly, we disable Rugged usage if Puma multi-threaded is
used (when Puma is configured to run with more than one thread).

This default behavior may not be the optimal configuration in some situations. If Rugged
plays an important role in your deployment, we suggest you benchmark to find the
optimal configuration:

- The safest option is to start with single-threaded Puma. When working with
  Rugged, single-threaded Puma works the same as Unicorn.
- To force Rugged to be used with multi-threaded Puma, you can use
  [feature flags](../../development/gitaly.md#legacy-rugged-code).
