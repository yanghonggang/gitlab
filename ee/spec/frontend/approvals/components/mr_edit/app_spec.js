import { mount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import MREditApp from 'ee/approvals/components/mr_edit/app.vue';
import MRRules from 'ee/approvals/components/mr_edit/mr_rules.vue';
import MRRulesHiddenInputs from 'ee/approvals/components/mr_edit/mr_rules_hidden_inputs.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import MREditModule from 'ee/approvals/stores/modules/mr_edit';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Approvals MREditApp', () => {
  let wrapper;
  let store;
  let axiosMock;

  const factory = () => {
    wrapper = mount(MREditApp, {
      localVue,
      store: new Vuex.Store(store),
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet('*');

    store = createStoreOptions(MREditModule());
    store.modules.approvals.state.hasLoaded = true;
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  describe('with empty rules', () => {
    beforeEach(() => {
      store.modules.approvals.state.rules = [];
      factory();
    });

    it('does not render MR rules', () => {
      expect(wrapper.find(MRRules).findAll('.js-name')).toHaveLength(0);
    });

    it('renders hidden inputs', () => {
      expect(
        wrapper
          .find('.js-approval-rules')
          .find(MRRulesHiddenInputs)
          .exists(),
      ).toBe(true);
    });
  });

  describe('with rules', () => {
    beforeEach(() => {
      store.modules.approvals.state.rules = [{ id: 7, approvers: [] }];
      factory();
    });

    it('renders MR rules', () => {
      expect(wrapper.find(MRRules).findAll('.js-name')).toHaveLength(1);
    });

    it('renders hidden inputs', () => {
      expect(
        wrapper
          .find('.js-approval-rules')
          .find(MRRulesHiddenInputs)
          .exists(),
      ).toBe(true);
    });
  });
});
