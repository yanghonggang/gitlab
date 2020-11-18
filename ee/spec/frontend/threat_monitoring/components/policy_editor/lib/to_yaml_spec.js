import { EndpointMatchModeLabel } from 'ee/threat_monitoring/components/policy_editor/constants';
import { buildRule } from 'ee/threat_monitoring/components/policy_editor/lib/rules';
import toYaml from 'ee/threat_monitoring/components/policy_editor/lib/to_yaml';

describe('toYaml', () => {
  let policy;

  beforeEach(() => {
    policy = { name: 'test-policy', endpointLabels: '', rules: [] };
  });

  it('returns yaml representation', () => {
    expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      network-policy.gitlab.com/disabled_by: gitlab
`);
  });

  describe('when description is not empty', () => {
    beforeEach(() => {
      policy.description = 'test description';
    });

    it('returns yaml representation', () => {
      expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
description: test description
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      network-policy.gitlab.com/disabled_by: gitlab
`);
    });
  });

  describe('when resourceVersion is not empty', () => {
    beforeEach(() => {
      policy.resourceVersion = '1234';
    });

    it('returns yaml representation', () => {
      expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
  resourceVersion: '1234'
spec:
  endpointSelector:
    matchLabels:
      network-policy.gitlab.com/disabled_by: gitlab
`);
    });
  });

  describe('when policy is enabled', () => {
    beforeEach(() => {
      policy.isEnabled = true;
    });

    it('returns yaml representation', () => {
      expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
spec:
  endpointSelector: {}
`);
    });
  });

  describe('when endpoint labels are not empty', () => {
    beforeEach(() => {
      policy.endpointMatchMode = EndpointMatchModeLabel;
      policy.endpointLabels = 'one two:val three: two:overwrite four: five';
    });

    it('returns yaml representation', () => {
      expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      one: ''
      two: overwrite
      three: ''
      four: ''
      five: ''
      network-policy.gitlab.com/disabled_by: gitlab
`);
    });
  });

  describe('with a rule', () => {
    beforeEach(() => {
      const rule = buildRule();
      rule.matchLabels = 'foo:bar';
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(toYaml(policy)).toEqual(`apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      network-policy.gitlab.com/disabled_by: gitlab
  ingress:
  - fromEndpoints:
    - matchLabels:
        foo: bar
`);
    });
  });
});
