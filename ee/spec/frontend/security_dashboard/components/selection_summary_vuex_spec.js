import { GlButton, GlFormSelect } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import SelectionSummary from 'ee/security_dashboard/components/selection_summary_vuex.vue';
import createStore from 'ee/security_dashboard/store/index';
import {
  SELECT_VULNERABILITY,
  RECEIVE_VULNERABILITIES_SUCCESS,
} from 'ee/security_dashboard/store/modules/vulnerabilities/mutation_types';
import waitForPromises from 'helpers/wait_for_promises';
import httpStatus from '~/lib/utils/http_status';
import mockDataVulnerabilities from '../store/modules/vulnerabilities/data/mock_data_vulnerabilities';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/vue_shared/plugins/global_toast');

describe('Selection Summary', () => {
  let store;
  let wrapper;
  let mock;

  const createComponent = () => {
    store = createStore();
    wrapper = mount(SelectionSummary, {
      localVue,
      store,
    });

    store.commit(`vulnerabilities/${RECEIVE_VULNERABILITIES_SUCCESS}`, {
      vulnerabilities: mockDataVulnerabilities,
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  const formSelect = () => wrapper.find(GlFormSelect);
  const dismissMessage = () => wrapper.find('[data-testid="dismiss-message"]');
  const dismissButton = () => wrapper.find(GlButton);

  const selectByIndex = index =>
    store.commit(`vulnerabilities/${SELECT_VULNERABILITY}`, mockDataVulnerabilities[index].id);

  it('renders the form', () => {
    expect(formSelect().exists()).toBe(true);
  });

  describe('dismiss message', () => {
    it('renders when no vulnerabilities selected', () => {
      expect(dismissMessage().text()).toBe('Dismiss 0 selected vulnerabilities as');
    });
    it('renders when 1 vulnerability selected', async () => {
      selectByIndex(0);

      await waitForPromises();

      expect(dismissMessage().text()).toBe('Dismiss 1 selected vulnerability as');
    });
    it('renders when 2 vulnerabilities selected', async () => {
      selectByIndex(0);
      selectByIndex(1);

      await waitForPromises();

      expect(dismissMessage().text()).toBe('Dismiss 2 selected vulnerabilities as');
    });
  });

  describe('dismiss button', () => {
    it('should be disabled if an option is not selected', () => {
      expect(dismissButton().exists()).toBe(true);
      expect(dismissButton().props().disabled).toBe(true);
    });

    it('should be enabled if a vulnerability is selected and dismissal reason is selected', async () => {
      expect(wrapper.vm.dismissalReason).toBe(null);
      expect(wrapper.findAll('option')).toHaveLength(4);

      selectByIndex(0);

      const option = formSelect()
        .findAll('option')
        .at(1);
      option.setSelected();
      formSelect().trigger('change');

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.dismissalReason).toEqual(option.attributes('value'));
      expect(dismissButton().props().disabled).toBe(false);
    });

    it('should make an API request for each vulnerability', async () => {
      mock.onPost().reply(httpStatus.OK);

      selectByIndex(0);
      selectByIndex(1);

      const option = formSelect()
        .findAll('option')
        .at(1);
      option.setSelected();
      formSelect().trigger('change');

      await waitForPromises();

      dismissButton().trigger('submit');

      await axios.waitForAll();

      expect(mock.history.post.length).toBe(2);
      expect(mock.history.post[0].data).toContain(option.attributes('value'));
    });
  });
});
