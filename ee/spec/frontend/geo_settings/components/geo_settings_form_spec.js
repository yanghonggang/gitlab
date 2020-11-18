import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import GeoSettingsForm from 'ee/geo_settings/components/geo_settings_form.vue';
import initStore from 'ee/geo_settings/store';
import * as types from 'ee/geo_settings/store/mutation_types';
import { visitUrl } from '~/lib/utils/url_utility';
import { STRING_OVER_255 } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('GeoSettingsForm', () => {
  let wrapper;
  let store;

  const createStore = () => {
    store = initStore();
  };

  const createComponent = () => {
    wrapper = mount(GeoSettingsForm, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoSettingsTimeoutField = () => wrapper.find('#settings-timeout-field');
  const findGeoSettingsAllowedIpField = () => wrapper.find('#settings-allowed-ip-field');
  const findGeoSettingsSaveButton = () => wrapper.find('[data-testid="settingsSaveButton"]');
  const findGeoSettingsCancelButton = () => wrapper.find('[data-testid="settingsCancelButton"]');
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  describe('template', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('renders Geo Node Form Name Field', () => {
      expect(findGeoSettingsTimeoutField().exists()).toBe(true);
    });

    it('renders Geo Node Form Url Field', () => {
      expect(findGeoSettingsAllowedIpField().exists()).toBe(true);
    });

    describe('Save Button', () => {
      describe('with errors on form', () => {
        beforeEach(() => {
          store.commit(types.SET_FORM_ERROR, {
            key: 'timeout',
            error: 'error',
          });
        });

        it('disables button', () => {
          expect(findGeoSettingsSaveButton().attributes('disabled')).toBeTruthy();
        });
      });

      describe('with no errors on form', () => {
        it('does not disable button', () => {
          expect(findGeoSettingsSaveButton().attributes('disabled')).toBeFalsy();
        });
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createStore();
      jest.spyOn(store, 'dispatch').mockImplementation();
      createComponent();
    });

    describe('save button', () => {
      it('calls updateGeoSettings when clicked', () => {
        findGeoSettingsSaveButton().vm.$emit('click');
        expect(store.dispatch).toHaveBeenCalledWith('updateGeoSettings');
      });
    });

    describe('cancel button', () => {
      it('calls visitUrl when clicked', () => {
        findGeoSettingsCancelButton().vm.$emit('click');
        expect(visitUrl).toHaveBeenCalledWith('/admin/geo/nodes');
      });
    });
  });

  describe('errors', () => {
    describe.each`
      data    | showError | errorMessage
      ${null} | ${true}   | ${"Connection timeout can't be blank"}
      ${''}   | ${true}   | ${"Connection timeout can't be blank"}
      ${0}    | ${true}   | ${'Connection timeout should be between 1-120'}
      ${121}  | ${true}   | ${'Connection timeout should be between 1-120'}
      ${10}   | ${false}  | ${null}
    `(`Timeout Field`, ({ data, showError, errorMessage }) => {
      beforeEach(() => {
        createStore();
        createComponent();
        findGeoSettingsTimeoutField().setValue(data);
        findGeoSettingsTimeoutField().trigger('blur');
      });

      it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
        expect(findGeoSettingsTimeoutField().classes('is-invalid')).toBe(showError);
        if (showError) {
          expect(findErrorMessage().text()).toBe(errorMessage);
        }
      });
    });

    describe.each`
      data               | showError | errorMessage
      ${null}            | ${true}   | ${"Allowed Geo IP can't be blank"}
      ${''}              | ${true}   | ${"Allowed Geo IP can't be blank"}
      ${STRING_OVER_255} | ${true}   | ${'Allowed Geo IP should be between 1 and 255 characters'}
      ${'asdf'}          | ${true}   | ${'Allowed Geo IP should contain valid IP addresses'}
      ${'1.1.1.1, asdf'} | ${true}   | ${'Allowed Geo IP should contain valid IP addresses'}
      ${'asdf, 1.1.1.1'} | ${true}   | ${'Allowed Geo IP should contain valid IP addresses'}
      ${'1.1.1.1'}       | ${false}  | ${null}
      ${'::/0'}          | ${false}  | ${null}
      ${'1.1.1.1, ::/0'} | ${false}  | ${null}
    `(`Allowed Geo IP Field`, ({ data, showError, errorMessage }) => {
      beforeEach(() => {
        createStore();
        createComponent();
        findGeoSettingsAllowedIpField().setValue(data);
        findGeoSettingsAllowedIpField().trigger('blur');
      });

      it(`${showError ? 'shows' : 'hides'} error when data is ${data}`, () => {
        expect(findGeoSettingsAllowedIpField().classes('is-invalid')).toBe(showError);
        if (showError) {
          expect(findErrorMessage().text()).toBe(errorMessage);
        }
      });
    });
  });
});
