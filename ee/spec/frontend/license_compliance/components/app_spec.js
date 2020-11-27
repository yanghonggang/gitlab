import { GlEmptyState, GlLoadingIcon, GlTab, GlTabs, GlAlert, GlBadge } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import LicenseComplianceApp from 'ee/license_compliance/components/app.vue';
import DetectedLicensesTable from 'ee/license_compliance/components/detected_licenses_table.vue';
import PipelineInfo from 'ee/license_compliance/components/pipeline_info.vue';
import { REPORT_STATUS } from 'ee/license_compliance/store/modules/list/constants';

import * as getters from 'ee/license_compliance/store/modules/list/getters';

import { LICENSE_APPROVAL_CLASSIFICATION } from 'ee/vue_shared/license_compliance/constants';
import LicenseManagement from 'ee/vue_shared/license_compliance/license_management.vue';
import {
  approvedLicense,
  blacklistedLicense,
} from 'ee_jest/vue_shared/license_compliance/mock_data';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';

Vue.use(Vuex);

let wrapper;

const readLicensePoliciesEndpoint = `${TEST_HOST}/license_management`;
const managedLicenses = [approvedLicense, blacklistedLicense];
const licenses = [{}, {}];
const emptyStateSvgPath = '/';
const documentationPath = '/';

const noop = () => {};

const transitionStub = () => ({
  render() {
    // eslint-disable-next-line no-underscore-dangle
    return this.$options._renderChildren;
  },
});

const createComponent = ({ state, props, options }) => {
  const fakeStore = new Vuex.Store({
    modules: {
      licenseManagement: {
        namespaced: true,
        state: {
          managedLicenses,
        },
        getters: {
          isAddingNewLicense: () => false,
          hasPendingLicenses: () => false,
          isLicenseBeingUpdated: () => () => false,
        },
        actions: {
          fetchManagedLicenses: noop,
          setLicenseApproval: noop,
        },
      },
      licenseList: {
        namespaced: true,
        state: {
          licenses,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
          },
          ...state,
        },
        actions: {
          fetchLicenses: noop,
        },
        getters,
      },
    },
  });

  const mountFunc = options && options.mount ? mount : shallowMount;

  wrapper = mountFunc(LicenseComplianceApp, {
    propsData: {
      emptyStateSvgPath,
      documentationPath,
      readLicensePoliciesEndpoint,
      ...props,
    },
    ...options,
    store: fakeStore,
    stubs: { transition: transitionStub() },
  });
};

const findByTestId = testId => wrapper.find(`[data-testid="${testId}"]`);

describe('Project Licenses', () => {
  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        state: { initialized: false },
      });
    });

    it('shows the loading component', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });

    it('does not show the empty state component', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });
  });

  describe('when empty state', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.jobNotSetUp,
          },
        },
      });
    });

    it('shows the empty state component', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });

    it('does not show the loading component', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('does not show the list of detected in project licenses', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(false);
    });

    it('does not show the list of license policies', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(false);
    });

    it('does not render any tabs', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(false);
      expect(wrapper.find(GlTab).exists()).toBe(false);
    });
  });

  describe('when page is shown', () => {
    beforeEach(() => {
      createComponent({
        state: {
          initialized: true,
          reportInfo: {
            jobPath: '/',
            generatedAt: '',
            status: REPORT_STATUS.ok,
          },
        },
      });
    });

    it('does not render a policy violations alert', () => {
      expect(wrapper.find(GlAlert).exists()).toBe(false);
    });

    it('renders a "Detected in project" tab and a "Policies" tab', () => {
      expect(wrapper.find(GlTabs).exists()).toBe(true);
      expect(wrapper.find(GlTab).exists()).toBe(true);
      expect(wrapper.findAll(GlTab)).toHaveLength(2);
    });

    it('it renders the "Detected in project" table', () => {
      expect(wrapper.find(DetectedLicensesTable).exists()).toBe(true);
    });

    it('it renders the "Policies" table', () => {
      expect(wrapper.find(LicenseManagement).exists()).toBe(true);
    });

    it('renders the pipeline info', () => {
      expect(wrapper.find(PipelineInfo).exists()).toBe(true);
    });

    describe.each`
      givenLocationHash | expectedActiveTab
      ${'#licenses'}    | ${'licenses'}
      ${'#policies'}    | ${'policies'}
    `(
      'when window.location contains the hash "$givenLocationHash"',
      ({ givenLocationHash, expectedActiveTab }) => {
        const originalLocation = window.location;

        beforeEach(() => {
          setWindowLocation(`http://foo.com/index${givenLocationHash}`);

          createComponent({
            state: {
              initialized: true,
              isLoading: false,
              licenses: [
                {
                  name: 'MIT',
                  classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED,
                  components: [],
                },
              ],
              pageInfo: 1,
            },
            options: {
              mount: true,
            },
          });
        });

        afterEach(() => {
          window.location = originalLocation;
        });

        it(`sets the active tab to be "${expectedActiveTab}"`, () => {
          expect(findByTestId(`${expectedActiveTab}Tab`).classes()).toContain('active');
        });
      },
    );

    describe('when the tabs are rendered', () => {
      const pageInfo = {
        total: 1,
      };

      beforeEach(() => {
        createComponent({
          state: {
            initialized: true,
            isLoading: false,
            licenses: [
              {
                name: 'MIT',
                classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED,
                components: [],
              },
            ],
            reportInfo: {
              jobPath: '/',
              generatedAt: '',
              status: REPORT_STATUS.ok,
            },
            pageInfo,
          },
          options: {
            mount: true,
          },
        });
      });

      it.each`
        givenActiveTab | expectedLocationHash
        ${'policies'}  | ${'#policies'}
        ${'licenses'}  | ${'#licenses'}
      `(
        'sets the location hash to "$expectedLocationHash" when the "$givenTab" tab is activate',
        ({ givenActiveTab, expectedLocationHash }) => {
          findByTestId(`${givenActiveTab}TabTitle`).trigger('click');

          return wrapper.vm.$nextTick().then(() => {
            expect(window.location.hash).toBe(expectedLocationHash);
          });
        },
      );

      it('it renders the correct count in "Detected in project" tab', () => {
        expect(
          wrapper
            .findAll(GlBadge)
            .at(0)
            .text(),
        ).toBe(pageInfo.total.toString());
      });

      it('it renders the correct count in "Policies" tab', () => {
        expect(
          wrapper
            .findAll(GlBadge)
            .at(1)
            .text(),
        ).toBe(managedLicenses.length.toString());
      });
    });

    describe('when there are policy violations', () => {
      beforeEach(() => {
        createComponent({
          state: {
            initialized: true,
            licenses: [{ classification: LICENSE_APPROVAL_CLASSIFICATION.DENIED }],
          },
        });
      });

      it('renders a policy violations alert', () => {
        expect(wrapper.find(GlAlert).exists()).toBe(true);
        expect(wrapper.find(GlAlert).text()).toContain(
          "Detected licenses that are out-of-compliance with the project's assigned policies",
        );
      });
    });
  });
});
