import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SecurityReportsSummary from 'ee/security_dashboard/components/security_reports_summary.vue';
import Modal from 'ee/vue_shared/security_reports/components/dast_modal.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { trimText } from 'helpers/text_helper';
import AccessorUtilities from '~/lib/utils/accessor';

describe('Security reports summary component', () => {
  useLocalStorageSpy();

  let wrapper;

  const createWrapper = options => {
    wrapper = shallowMount(SecurityReportsSummary, {
      propsData: {
        summary: {},
        ...options?.propsData,
      },
      stubs: {
        GlSprintf,
        GlCard: { template: '<div><slot name="header" /><slot /></div>' },
        Modal,
      },
      ...options,
    });
  };

  const findToggleButton = () => wrapper.find('[data-testid="collapse-button"]');
  const findModalButton = () => wrapper.find('[data-testid="modal-button"]');

  beforeEach(() => {
    jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(true);
  });

  afterEach(() => {
    wrapper.destroy();
    localStorage.clear();
  });

  it.each`
    dastProps                                                  | string
    ${{ vulnerabilitiesCount: 0, scannedResourcesCount: 123 }} | ${'0 vulnerabilities (123 URLs scanned)'}
    ${{ vulnerabilitiesCount: 481, scannedResourcesCount: 0 }} | ${'481 vulnerabilities (0 URLs scanned)'}
    ${{ vulnerabilitiesCount: 1, scannedResourcesCount: 1 }}   | ${'1 vulnerability (1 URL scanned)'}
    ${{ vulnerabilitiesCount: 321 }}                           | ${'321 vulnerabilities'}
    ${{ vulnerabilitiesCount: 0 }}                             | ${'0 vulnerabilities'}
  `('shows security report summary $string', ({ dastProps, string }) => {
    createWrapper({
      propsData: {
        summary: {
          dast: dastProps,
        },
      },
    });

    expect(trimText(wrapper.text())).toContain(string);
    expect(findModalButton().exists()).toBe(false);
  });

  it.each`
    dastProps
    ${{ scannedResourcesCount: 890 }}
    ${{ scannedResourcesCount: 0 }}
  `(
    'does not show the scanned resources count if there is no vulnerabilities count',
    ({ dastProps }) => {
      createWrapper({
        propsData: {
          summary: {
            dast: dastProps,
          },
        },
      });

      expect(trimText(wrapper.text())).not.toContain('URLs scanned');
    },
  );

  it.each`
    summaryProp                                              | string
    ${{ dast: { vulnerabilitiesCount: 123 } }}               | ${'DAST'}
    ${{ sast: { vulnerabilitiesCount: 123 } }}               | ${'SAST'}
    ${{ containerScanning: { vulnerabilitiesCount: 123 } }}  | ${'Container Scanning'}
    ${{ dependencyScanning: { vulnerabilitiesCount: 123 } }} | ${'Dependency Scanning'}
  `('shows user-friendly scanner name for $string', ({ summaryProp, string }) => {
    createWrapper({
      propsData: {
        summary: summaryProp,
      },
    });

    expect(trimText(wrapper.text())).toContain(string);
  });

  it.each`
    summaryProp                     | report
    ${{ dast: null }}               | ${'DAST'}
    ${{ sast: null }}               | ${'SAST'}
    ${{ containerScanning: null }}  | ${'Container Scanning'}
    ${{ dependencyScanning: null }} | ${'Dependency Scanning'}
  `('does not show $report report if scanner did not run', ({ summaryProp, report }) => {
    createWrapper({
      propsData: {
        summary: summaryProp,
      },
    });

    expect(trimText(wrapper.text())).not.toContain(report);
  });

  describe('collapsible behavior', () => {
    const LOCAL_STORAGE_KEY = 'hide_pipelines_security_reports_summary_details';

    describe('initially visible', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('set local storage item to 1 when summary is hidden', async () => {
        wrapper.setData({ isVisible: false });
        await wrapper.vm.$nextTick();

        expect(localStorage.setItem).toHaveBeenCalledWith(LOCAL_STORAGE_KEY, '1');
      });

      it('toggle button has the correct label', () => {
        expect(findToggleButton().text()).toBe('Hide details');
      });
    });

    describe('initially hidden', () => {
      beforeEach(() => {
        localStorage.setItem(LOCAL_STORAGE_KEY, '1');
        createWrapper();
      });

      it('removes local storage item when summary is shown', async () => {
        wrapper.setData({ isVisible: true });
        await wrapper.vm.$nextTick();

        expect(localStorage.removeItem).toHaveBeenCalledWith(LOCAL_STORAGE_KEY);
      });

      it('toggle button has the correct label', () => {
        expect(findToggleButton().text()).toBe('Show details');
      });
    });
  });

  describe('when localStorage is unavailable', () => {
    beforeEach(() => {
      jest.spyOn(AccessorUtilities, 'isLocalStorageAccessSafe').mockReturnValue(false);
      createWrapper();
    });

    it('does not show the collapse button', () => {
      expect(findToggleButton().exists()).toBe(false);
    });
  });

  describe('with scanned resources', () => {
    const glModalDirective = jest.fn();

    const dastProps = {
      vulnerabilitiesCount: 10,
      scannedResourcesCount: 149,
      scannedResources: {
        nodes: [
          {
            requestMethod: 'GET',
            url: 'https://weburl',
          },
        ],
      },
    };

    beforeEach(() => {
      createWrapper({
        directives: {
          glModal: {
            bind(el, { modifiers }) {
              glModalDirective(modifiers);
            },
          },
        },
        propsData: {
          summary: { dast: dastProps },
        },
      });
    });

    it('should have the modal with id dastUrl', () => {
      const modal = wrapper.find(Modal);

      expect(modal.exists()).toBe(true);
      expect(modal.attributes('modalid')).toBe('dastUrl');
    });

    it('should contain a link with Scanned URLs count', () => {
      expect(findModalButton().exists()).toBe(true);
      expect(findModalButton().text()).toContain(
        `(${dastProps.scannedResourcesCount} URLs scanned)`,
      );
    });

    it('should link it to the given modal', () => {
      expect(glModalDirective).toHaveBeenCalledWith({ dastUrl: true });
    });
  });
});
