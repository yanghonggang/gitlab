import { shallowMount } from '@vue/test-utils';
import EnvironmentPicker from 'ee/threat_monitoring/components/environment_picker.vue';
import {
  INVALID_CURRENT_ENVIRONMENT_NAME,
  ALL_ENVIRONMENT_NAME,
} from 'ee/threat_monitoring/constants';
import createStore from 'ee/threat_monitoring/store';
import { mockEnvironmentsResponse } from '../mock_data';

const mockEnvironments = mockEnvironmentsResponse.environments;
const currentEnvironment = mockEnvironments[1];

describe('EnvironmentPicker component', () => {
  let store;
  let wrapper;

  const factory = state => {
    store = createStore();
    Object.assign(store.state.threatMonitoring, state);

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(EnvironmentPicker, {
      store,
    });
  };

  const findEnvironmentsDropdown = () => wrapper.find({ ref: 'environmentsDropdown' });
  const findEnvironmentsDropdownItems = () => wrapper.findAll({ ref: 'environmentsDropdownItem' });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('the environments dropdown', () => {
    describe('given there are no environments', () => {
      beforeEach(() => {
        factory();
      });

      it('has text set to the INVALID_CURRENT_ENVIRONMENT_NAME', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(INVALID_CURRENT_ENVIRONMENT_NAME);
      });

      it('has no dropdown items', () => {
        expect(findEnvironmentsDropdownItems()).toHaveLength(0);
      });
    });
    describe('given there are environments', () => {
      beforeEach(() => {
        factory({
          environments: mockEnvironments,
          currentEnvironmentId: currentEnvironment.id,
        });
      });

      it('is not disabled', () => {
        expect(findEnvironmentsDropdown().attributes().disabled).toBe(undefined);
      });

      it('has text set to the current environment', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(currentEnvironment.name);
      });

      it('has dropdown items for each environment', () => {
        const dropdownItems = findEnvironmentsDropdownItems();
        mockEnvironments.forEach((environment, i) => {
          const dropdownItem = dropdownItems.at(i);
          expect(dropdownItem.text()).toBe(environment.name);
          dropdownItem.vm.$emit('click');
          expect(store.dispatch).toHaveBeenCalledWith(
            'threatMonitoring/setCurrentEnvironmentId',
            environment.id,
          );
        });
      });
    });
    describe('with includeAll enabled', () => {
      beforeEach(() => {
        factory({
          environments: mockEnvironments,
          currentEnvironmentId: currentEnvironment.id,
          allEnvironments: true,
        });
        wrapper = shallowMount(EnvironmentPicker, {
          propsData: {
            includeAll: true,
          },
          store,
        });
      });

      it('has text set to the all environment option', () => {
        expect(findEnvironmentsDropdown().attributes().text).toBe(ALL_ENVIRONMENT_NAME);
      });
    });
  });

  describe.each`
    context                            | isLoadingEnvironments | isLoadingWafStatistics | isLoadingNetworkPolicyStatistics | environments
    ${'environments are loading'}      | ${true}               | ${false}               | ${false}                         | ${mockEnvironments}
    ${'WAF statistics are loading'}    | ${false}              | ${true}                | ${false}                         | ${mockEnvironments}
    ${'NetPol statistics are loading'} | ${false}              | ${false}               | ${true}                          | ${mockEnvironments}
    ${'there are no environments'}     | ${false}              | ${false}               | ${false}                         | ${[]}
  `(
    'given $context',
    ({
      isLoadingEnvironments,
      isLoadingWafStatistics,
      isLoadingNetworkPolicyStatistics,
      environments,
    }) => {
      beforeEach(() => {
        factory({
          environments,
          isLoadingEnvironments,
          isLoadingWafStatistics,
          isLoadingNetworkPolicyStatistics,
        });

        return wrapper.vm.$nextTick();
      });

      it('disables the environments dropdown', () => {
        expect(findEnvironmentsDropdown().attributes('disabled')).toBe('true');
      });
    },
  );
});
