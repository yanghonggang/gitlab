import {
  EndpointMatchModeAny,
  EndpointMatchModeLabel,
  RuleDirectionInbound,
  RuleDirectionOutbound,
  PortMatchModeAny,
  PortMatchModePortProtocol,
  RuleTypeEndpoint,
  RuleTypeEntity,
  RuleTypeCIDR,
  RuleTypeFQDN,
  EntityTypes,
} from 'ee/threat_monitoring/components/policy_editor/constants';
import fromYaml from 'ee/threat_monitoring/components/policy_editor/lib/from_yaml';
import { buildRule } from 'ee/threat_monitoring/components/policy_editor/lib/rules';
import toYaml from 'ee/threat_monitoring/components/policy_editor/lib/to_yaml';

describe('fromYaml', () => {
  let policy;

  const cidrExample = '20.1.1.1/32 20.1.1.2/32';
  const portExample = '80 81/udp 82/tcp';

  beforeEach(() => {
    policy = {
      name: 'test-policy',
      endpointLabels: '',
      rules: [],
      isEnabled: true,
    };
  });

  it('returns policy object', () => {
    expect(fromYaml(toYaml(policy))).toMatchObject({
      name: 'test-policy',
      isEnabled: true,
      endpointMatchMode: EndpointMatchModeAny,
      endpointLabels: '',
      rules: [],
    });
  });

  describe('when description is not empty', () => {
    beforeEach(() => {
      policy.description = 'test description';
    });

    it('returns policy object', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        description: 'test description',
      });
    });
  });

  describe('when resourceVersion is not empty', () => {
    beforeEach(() => {
      policy.resourceVersion = '1234';
    });

    it('returns policy object', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        resourceVersion: '1234',
      });
    });
  });

  describe('when policy is disabled', () => {
    beforeEach(() => {
      policy.isEnabled = false;
    });

    it('returns policy object', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        isEnabled: false,
      });
    });
  });

  describe('when endpoint labels are not empty', () => {
    it('returns policy object', () => {
      // test that duplicated keys are supported
      const manifest = `apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: test-policy
spec:
  endpointSelector:
    matchLabels:
      one: ''
      two: value
      two: overwrite
      three: ''
      four: ''
      five: ''
      network-policy.gitlab.com/disabled_by: gitlab
`;

      expect(fromYaml(manifest)).toMatchObject({
        endpointMatchMode: EndpointMatchModeLabel,
        endpointLabels: 'one: two:overwrite three: four: five:',
      });
    });
  });

  describe('with an inbound endpoint rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEndpoint);
      rule.matchLabels = 'one two:value two:overwrite';
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeEndpoint,
            direction: RuleDirectionInbound,
            matchLabels: 'one: two:overwrite',
            portMatchMode: PortMatchModeAny,
            ports: '',
          },
        ],
      });
    });
  });

  describe('with an outbound endpoint rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEndpoint);
      rule.matchLabels = 'one two:value two:overwrite';
      rule.direction = RuleDirectionOutbound;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeEndpoint,
            direction: RuleDirectionOutbound,
            matchLabels: 'one: two:overwrite',
          },
        ],
      });
    });
  });

  describe('with an inbound entity rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEntity);
      rule.entities = [EntityTypes.HOST, EntityTypes.WORLD];
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeEntity,
            direction: RuleDirectionInbound,
            entities: [EntityTypes.HOST, EntityTypes.WORLD],
          },
        ],
      });
    });
  });

  describe('with an outbound entity rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEntity);
      rule.entities = [EntityTypes.HOST, EntityTypes.WORLD];
      rule.direction = RuleDirectionOutbound;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeEntity,
            direction: RuleDirectionOutbound,
            entities: [EntityTypes.HOST, EntityTypes.WORLD],
          },
        ],
      });
    });
  });

  describe('with an inbound cidr rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeCIDR);
      rule.cidr = cidrExample;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeCIDR,
            direction: RuleDirectionInbound,
            cidr: cidrExample,
          },
        ],
      });
    });
  });

  describe('with an outbound cidr rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeCIDR);
      rule.cidr = cidrExample;
      rule.direction = RuleDirectionOutbound;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeCIDR,
            direction: RuleDirectionOutbound,
            cidr: cidrExample,
          },
        ],
      });
    });
  });

  describe('with an outbound fqdn rule', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeFQDN);
      rule.fqdn = 'remote-service.com another-service.com';
      rule.direction = RuleDirectionOutbound;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            ruleType: RuleTypeFQDN,
            direction: RuleDirectionOutbound,
            fqdn: 'remote-service.com another-service.com',
          },
        ],
      });
    });
  });

  describe('with an empty inbound rule and port matcher', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEndpoint);
      rule.portMatchMode = PortMatchModePortProtocol;
      rule.ports = portExample;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            portMatchMode: PortMatchModePortProtocol,
            ports: '80/tcp 81/udp 82/tcp',
          },
        ],
      });
    });
  });

  describe('with an empty outbound rule and port matcher', () => {
    beforeEach(() => {
      const rule = buildRule(RuleTypeEndpoint);
      rule.portMatchMode = PortMatchModePortProtocol;
      rule.ports = portExample;
      rule.direction = RuleDirectionOutbound;
      policy.rules = [rule];
    });

    it('returns yaml representation', () => {
      expect(fromYaml(toYaml(policy))).toMatchObject({
        rules: [
          {
            portMatchMode: PortMatchModePortProtocol,
            ports: '80/tcp 81/udp 82/tcp',
          },
        ],
      });
    });
  });
});
