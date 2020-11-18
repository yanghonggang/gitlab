import { GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import LicenseIssueBody from 'ee/vue_shared/license_compliance/components/add_license_form.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';

const KNOWN_LICENSES = [{ name: 'BSD' }, { name: 'Apache' }];

let wrapper;
let vm;

const createComponent = (props = {}, mountFn = shallowMount) => {
  wrapper = mountFn(LicenseIssueBody, { propsData: { knownLicenses: KNOWN_LICENSES, ...props } });
  vm = wrapper.vm;
};

describe('AddLicenseForm', () => {
  const findSubmitButton = () => wrapper.find('.js-submit');
  const findCancelButton = () => wrapper.find('.js-cancel');
  const findRadioInputs = () => wrapper.find(GlFormRadioGroup).findAll(GlFormRadio);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    vm = undefined;
    wrapper.destroy();
  });

  describe('interaction', () => {
    it('clicking the Submit button submits the data and closes the form', async () => {
      const name = 'LICENSE_TEST';

      createComponent({}, mount);
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      wrapper.setData({ approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED, licenseName: name });

      await Vue.nextTick();

      const linkEl = findSubmitButton();
      linkEl.trigger('click');

      expect(vm.$emit).toHaveBeenCalledWith('addLicense', {
        newStatus: LICENSE_APPROVAL_STATUS.ALLOWED,
        license: { name },
      });
    });

    it('clicking the Cancel button closes the form', () => {
      createComponent({}, mount);
      const linkEl = findCancelButton();
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      linkEl.trigger('click');

      expect(vm.$emit).toHaveBeenCalledWith('closeForm');
    });
  });

  describe('computed', () => {
    describe('submitDisabled', () => {
      it('is true if the approvalStatus is empty', () => {
        wrapper.setData({ licenseName: 'FOO', approvalStatus: '' });

        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the licenseName is empty', () => {
        wrapper.setData({ licenseName: '', approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED });

        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the entered license is duplicated', () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        wrapper.setData({ licenseName: 'FOO', approvalStatus: LICENSE_APPROVAL_STATUS.ALLOWED });

        expect(vm.submitDisabled).toBe(true);
      });
    });

    describe('isInvalidLicense', () => {
      it('is true if the entered license is duplicated', () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        wrapper.setData({ licenseName: 'FOO' });

        expect(vm.isInvalidLicense).toBe(true);
      });

      it('is false if the entered license is unique', () => {
        createComponent({ managedLicenses: [{ name: 'FOO' }] });
        wrapper.setData({ licenseName: 'FOO2' });

        expect(vm.isInvalidLicense).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders the license select dropdown', () => {
      const dropdownElement = wrapper.find('#js-license-dropdown');

      expect(dropdownElement.exists()).toBe(true);
    });

    it('renders the license approval radio buttons dropdown', () => {
      const approvalOptions = findRadioInputs();

      expect(approvalOptions).toHaveLength(2);
      expect(approvalOptions.at(0).text()).toBe('Allow');
      expect(approvalOptions.at(1).text()).toBe('Deny');
    });

    it('renders error text, if there is a duplicate license', async () => {
      createComponent({ managedLicenses: [{ name: 'FOO' }] });
      wrapper.setData({ licenseName: 'FOO' });
      await Vue.nextTick();

      const feedbackElement = wrapper.find('.invalid-feedback');

      expect(feedbackElement.exists()).toBe(true);
      expect(feedbackElement.classes()).toContain('d-block');
      expect(feedbackElement.text()).toBe('This license already exists in this project.');
    });

    it('shows radio button descriptions, if licenseComplianceDeniesMr feature flag is enabled', async () => {
      wrapper = shallowMount(LicenseIssueBody, {
        propsData: {
          managedLicenses: [{ name: 'FOO' }],
          knownLicenses: KNOWN_LICENSES,
        },
        provide: {
          glFeatures: { licenseComplianceDeniesMr: true },
        },
      });

      await Vue.nextTick();

      const descriptionElement = wrapper.findAll('.text-secondary');

      expect(descriptionElement.at(0).text()).toBe('Acceptable license to be used in the project');

      expect(descriptionElement.at(1).text()).toBe(
        'Disallow merge request if detected and will instruct developer to remove',
      );
    });

    it('does not show radio button descriptions, if licenseComplianceDeniesMr feature flag is disabled', () => {
      createComponent({ managedLicenses: [{ name: 'FOO' }] });
      wrapper.setData({ licenseName: 'FOO' });
      return Vue.nextTick().then(() => {
        expect(findRadioInputs().at(0).element).toMatchSnapshot();
        expect(findRadioInputs().at(1).element).toMatchSnapshot();
      });
    });

    it('disables submit, if the form is invalid', async () => {
      wrapper.setData({ licenseName: '' });
      await Vue.nextTick();

      expect(vm.submitDisabled).toBe(true);

      const submitButton = findSubmitButton();

      expect(submitButton.exists()).toBe(true);
      expect(submitButton.props().disabled).toBe(true);
    });

    it('disables submit and cancel while a new license is being added', async () => {
      wrapper.setProps({ loading: true });
      await Vue.nextTick();

      const submitButton = findSubmitButton();
      const cancelButton = findCancelButton();

      expect(submitButton.exists()).toBe(true);
      expect(submitButton.props().disabled).toBe(true);
      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.props().disabled).toBe(true);
    });
  });
});
