import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import store from 'ee/geo_replicable/store';
import GeoReplicableStatus from 'ee/geo_replicable/components/geo_replicable_status.vue';
import {
  FILTER_STATES,
  STATUS_ICON_NAMES,
  STATUS_ICON_CLASS,
  DEFAULT_STATUS,
} from 'ee/geo_replicable/store/constants';
import Icon from '~/vue_shared/components/icon.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableStatus', () => {
  let wrapper;

  const propsData = {
    status: FILTER_STATES.SYNCED.value,
  };

  const createComponent = () => {
    wrapper = mount(GeoReplicableStatus, {
      localVue,
      store,
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoReplicableStatusContainer = () => wrapper.find('div');
  const findIcon = () => findGeoReplicableStatusContainer().find(Icon);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders status container', () => {
      expect(findGeoReplicableStatusContainer().exists()).toBe(true);
    });
  });

  describe.each`
    status                         | iconName                                          | iconClass
    ${FILTER_STATES.SYNCED.value}  | ${STATUS_ICON_NAMES[FILTER_STATES.SYNCED.value]}  | ${STATUS_ICON_CLASS[FILTER_STATES.SYNCED.value]}
    ${FILTER_STATES.PENDING.value} | ${STATUS_ICON_NAMES[FILTER_STATES.PENDING.value]} | ${STATUS_ICON_CLASS[FILTER_STATES.PENDING.value]}
    ${FILTER_STATES.FAILED.value}  | ${STATUS_ICON_NAMES[FILTER_STATES.FAILED.value]}  | ${STATUS_ICON_CLASS[FILTER_STATES.FAILED.value]}
    ${DEFAULT_STATUS}              | ${STATUS_ICON_NAMES[DEFAULT_STATUS]}              | ${STATUS_ICON_CLASS[DEFAULT_STATUS]}
  `(`iconProperties`, ({ status, iconName, iconClass }) => {
    beforeEach(() => {
      propsData.status = status;
      createComponent();
    });

    describe(`with filter set to ${status}`, () => {
      beforeEach(() => {
        wrapper.vm.icon = wrapper.vm.iconProperties();
      });

      it(`sets icon.name to ${iconName}`, () => {
        expect(wrapper.vm.icon.name).toEqual(iconName);
      });

      it(`sets icon.cssClass to ${iconClass}`, () => {
        expect(wrapper.vm.icon.cssClass).toEqual(iconClass);
      });

      it(`sets svg to ic-${iconName}`, () => {
        expect(findIcon().classes()).toContain(`ic-${wrapper.vm.icon.name}`);
      });
    });
  });
});
