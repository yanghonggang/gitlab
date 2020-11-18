import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MRRules from 'ee/approvals/components/mr_edit/mr_rules.vue';
import RuleControls from 'ee/approvals/components/rule_controls.vue';
import Rules from 'ee/approvals/components/rules.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { createEmptyRule, createMRRule, createMRRuleWithSource } from '../../mock_data';

const { HEADERS } = Rules;

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Approvals MRRules', () => {
  let wrapper;
  let store;
  let approvalRules;
  let OriginalMutationObserver;

  const factory = () => {
    if (approvalRules) {
      store.modules.approvals.state.rules = approvalRules;
    }

    wrapper = mount(localVue.extend(MRRules), {
      localVue,
      store: new Vuex.Store(store),
      attachToDocument: true,
    });
  };

  const findHeaders = () => wrapper.findAll('thead th').wrappers.map(x => x.text());
  const findRuleName = () => wrapper.find('.js-name');
  const findRuleIndicator = () => wrapper.find({ ref: 'indicator' });
  const findRuleMembers = () =>
    wrapper
      .find('td.js-members')
      .find(UserAvatarList)
      .props('items');
  const findRuleControls = () => wrapper.find('td.js-controls').find(RuleControls);
  const callTargetBranchHandler = MutationObserverSpy => {
    const onTargetBranchMutationHandler = MutationObserverSpy.mock.calls[0][0];
    return onTargetBranchMutationHandler();
  };

  beforeEach(() => {
    OriginalMutationObserver = global.MutationObserver;
    global.MutationObserver = jest
      .fn()
      .mockImplementation(args => new OriginalMutationObserver(args));

    store = createStoreOptions(MREditModule());
    store.modules.approvals.state = {
      hasLoaded: true,
      rules: [],
      targetBranch: 'master',
    };
    store.modules.approvals.actions.putRule = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
    approvalRules = null;
    global.MutationObserver = OriginalMutationObserver;
  });

  describe('when editing a MR', () => {
    const initialTargetBranch = 'master';
    let targetBranchInputElement;

    beforeEach(() => {
      targetBranchInputElement = document.createElement('input');
      targetBranchInputElement.id = 'merge_request_target_branch';
      targetBranchInputElement.value = initialTargetBranch;
      document.body.appendChild(targetBranchInputElement);

      store.modules.approvals.actions = {
        fetchRules: jest.fn(),
        addEmptyRule: jest.fn(),
        setEmptyRule: jest.fn(),
        setTargetBranch: jest.fn(),
      };
      store.state.settings.mrSettingsPath = 'some/path';
      store.state.settings.eligibleApproversDocsPath = 'some/path';
      store.state.settings.allowMultiRule = true;
    });

    afterEach(() => {
      targetBranchInputElement.parentNode.removeChild(targetBranchInputElement);
    });

    it('updates the target branch data when the target branch dropdown is changed', () => {
      factory();
      callTargetBranchHandler(global.MutationObserver);
      expect(store.modules.approvals.actions.setTargetBranch).toHaveBeenCalled();
    });

    it('re-fetches rules when target branch has changed', () => {
      factory();
      store.modules.approvals.state.targetBranch = 'master123';

      return wrapper.vm.$nextTick().then(() => {
        expect(store.modules.approvals.actions.fetchRules).toHaveBeenCalled();
      });
    });

    it('disconnects MutationObserver when component gets destroyed', () => {
      const mockDisconnect = jest.fn();
      global.MutationObserver.mockImplementation(() => ({
        disconnect: mockDisconnect,
        observe: jest.fn(),
      }));
      factory();
      wrapper.destroy();
      expect(mockDisconnect).toHaveBeenCalled();
    });

    describe('rule indicator', () => {
      const falseOverriddenRule = createMRRuleWithSource({ overridden: false });

      it.each`
        rules                       | indicator                         | desc
        ${createMRRuleWithSource()} | ${'Overridden'}                   | ${'indicates "Overridden" for overridden rules'}
        ${createMRRule()}           | ${'Added for this merge request'} | ${'indicates "Added for this merge request" for local rules'}
        ${falseOverriddenRule}      | ${''}                             | ${'has no indicator for non-overridden rules'}
      `('$desc', ({ rules, indicator }) => {
        store.modules.approvals.state.rules = [rules];
        factory();

        expect(findRuleIndicator().text()).toBe(indicator);
      });
    });
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
      store.state.settings.eligibleApproversDocsPath = 'some/path';
    });

    it('should always have any_approver rule', () => {
      store.modules.approvals.state.rules = [createMRRule()];
      factory();

      expect(store.modules.approvals.state.rules).toHaveLength(2);
    });

    it('should always display any_approver first', () => {
      store.modules.approvals.state.rules = [createMRRule()];
      factory();

      expect(store.modules.approvals.state.rules[0].ruleType).toBe('any_approver');
    });

    it('should only have 1 any_approver', () => {
      store.modules.approvals.state.rules = [createEmptyRule(), createMRRule()];
      factory();

      const anyApproverCount = store.modules.approvals.state.rules.filter(
        rule => rule.ruleType === 'any_approver',
      );

      expect(anyApproverCount).toHaveLength(1);
    });

    it('renders headers when there are multiple rules', () => {
      store.modules.approvals.state.rules = [createEmptyRule(), createMRRule()];
      factory();

      expect(findHeaders()).toEqual([HEADERS.name, HEADERS.members, HEADERS.approvalsRequired, '']);
    });

    it('renders headers when there is a single any rule', () => {
      store.modules.approvals.state.rules = [createEmptyRule()];
      factory();

      expect(findHeaders()).toEqual([HEADERS.members, '', HEADERS.approvalsRequired, '']);
    });

    it('renders headers when there is a single named rule', () => {
      store.modules.approvals.state.rules = [createMRRule()];
      factory();

      expect(findHeaders()).toEqual([HEADERS.name, HEADERS.members, HEADERS.approvalsRequired, '']);
    });

    describe('with sourced MR rule', () => {
      const expected = createMRRuleWithSource();

      beforeEach(() => {
        approvalRules = [createMRRuleWithSource()];

        factory();
      });

      it('shows name', () => {
        expect(findRuleName().text()).toEqual(expected.name);
      });

      it('shows members', () => {
        expect(findRuleMembers()).toEqual(expected.approvers);
      });
    });

    describe('with custom MR rule', () => {
      const expected = createMRRule();

      beforeEach(() => {
        approvalRules = [createMRRule()];
      });

      it('shows controls', () => {
        factory();

        const controls = findRuleControls();

        expect(controls.exists()).toBe(true);
        expect(controls.props('rule')).toEqual(expected);
      });

      describe('with settings cannot edit', () => {
        beforeEach(() => {
          store.state.settings.canEdit = false;
          factory();
        });

        it('hides controls', () => {
          const controls = findRuleControls();

          expect(controls.exists()).toBe(false);
        });
      });
    });
  });

  describe('when allow single rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = false;
      store.state.settings.eligibleApproversDocsPath = 'some/path';
    });

    it('should only show single regular rule', () => {
      store.modules.approvals.state.rules = [createMRRule()];
      factory();

      expect(store.modules.approvals.state.rules[0].ruleType).toBe('regular');
      expect(store.modules.approvals.state.rules).toHaveLength(1);
    });

    it('should only show single any_approver rule', () => {
      store.modules.approvals.state.rules = [createEmptyRule()];
      factory();

      expect(store.modules.approvals.state.rules[0].ruleType).toBe('any_approver');
      expect(store.modules.approvals.state.rules).toHaveLength(1);
    });

    it('does not show name header for any rule', () => {
      store.modules.approvals.state.rules = [createEmptyRule()];
      factory();

      expect(findHeaders()).not.toContain(HEADERS.name);
    });

    it('does not show approvers header for regular rule', () => {
      store.modules.approvals.state.rules = [createMRRule()];
      factory();

      expect(findHeaders()).toEqual([HEADERS.name, HEADERS.members, HEADERS.approvalsRequired, '']);
    });

    describe('with source rule', () => {
      const expected = createMRRuleWithSource();

      beforeEach(() => {
        approvalRules = [createMRRuleWithSource()];

        factory();
      });

      it('shows name', () => {
        expect(findRuleName().text()).toEqual(expected.name);
      });

      it('shows controls', () => {
        expect(findRuleControls().exists()).toBe(true);
      });
    });
  });
});
