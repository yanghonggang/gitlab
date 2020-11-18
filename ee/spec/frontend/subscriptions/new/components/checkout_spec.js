import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ProgressBar from 'ee/registrations/components/progress_bar.vue';
import Component from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';

describe('Checkout', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let store;
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(Component, {
      store,
    });
  };

  const findProgressBar = () => wrapper.find(ProgressBar);

  beforeEach(() => {
    store = createStore();
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([[true, true], [false, false]])('when isNewUser=%s', (isNewUser, visible) => {
    beforeEach(() => {
      store.state.isNewUser = isNewUser;
    });

    it(`progress bar visibility is ${visible}`, () => {
      expect(findProgressBar().exists()).toBe(visible);
    });
  });

  describe('passing the correct options to the progress bar component', () => {
    beforeEach(() => {
      store.state.isNewUser = true;
    });

    it('passes the steps', () => {
      expect(findProgressBar().props('steps')).toEqual([
        'Your profile',
        'Checkout',
        'Your GitLab group',
      ]);
    });

    it('passes the current step', () => {
      expect(findProgressBar().props('currentStep')).toEqual('Checkout');
    });
  });
});
