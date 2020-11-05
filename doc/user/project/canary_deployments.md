---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Canary Deployments **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1659) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.1.

A popular [Continuous Deployment](https://en.wikipedia.org/wiki/Continuous_deployment)
strategy, where a small portion of the fleet is updated to the new version of
your application.

## Overview

When embracing [Continuous Delivery](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/), a company needs to decide what
type of deployment strategy to use. One of the most popular strategies is canary
deployments, where a small portion of the fleet is updated to the new version
first. This subset, the canaries, then serve as the proverbial
[canary in the coal mine](https://en.wiktionary.org/wiki/canary_in_a_coal_mine).

If there is a problem with the new version of the application, only a small
percentage of users are affected and the change can either be fixed or quickly
reverted.

Leveraging [Kubernetes' Canary deployments](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#canary-deployments), visualize your canary
deployments right inside the [Deploy Board](deploy_boards.md), without the need to leave GitLab.

## Use cases

Canary deployments can be used when you want to ship features to only a portion of
your pods fleet and watch their behavior as a percentage of your user base
visits the temporarily deployed feature. If all works well, you can deploy the
feature to production knowing that it won't cause any problems.

Canary deployments are also especially useful for backend refactors, performance
improvements, or other changes where the user interface doesn't change, but you
want to make sure the performance stays the same, or improves. Developers need
to be careful when using canaries with user-facing changes, because by default,
requests from the same user will be randomly distributed between canary and
non-canary pods, which could result in confusion or even errors. If needed, you
may want to consider [setting `service.spec.sessionAffinity` to `ClientIP` in
your Kubernetes service definitions](https://kubernetes.io/docs/concepts/services-networking/service/#virtual-ips-and-service-proxies), but that is beyond the scope of
this document.

## Enabling Canary Deployments

Canary deployments require that you properly configure Deploy Boards:

1. Follow the steps to [enable Deploy Boards](deploy_boards.md#enabling-deploy-boards).
1. To track canary deployments you need to label your Kubernetes deployments and
   pods with `track: canary`. To get started quickly, you can use the [Auto Deploy](../../topics/autodevops/stages.md#auto-deploy)
   template for canary deployments that GitLab provides.

Depending on the deploy, the label should be either `stable` or `canary`.
GitLab assumes the track label is `stable` if the label is blank or missing.
Any other track label is considered `canary` (temporary).
This allows GitLab to discover whether a deployment is stable or canary (temporary).

Once all of the above are set up and the pipeline has run at least once,
navigate to the environments page under **Pipelines > Environments**.
As the pipeline executes Deploy Boards will clearly mark canary pods, enabling
quick and easy insight into the status of each environment and deployment.

Canary deployments are marked with a yellow dot in the Deploy Board so that you
can easily notice them.

![Canary deployments on Deploy Board](img/deploy_boards_canary_deployments.png)
