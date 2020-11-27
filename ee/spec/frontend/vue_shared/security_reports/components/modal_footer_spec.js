import { mount } from '@vue/test-utils';
import DismissButton from 'ee/vue_shared/security_reports/components/dismiss_button.vue';
import component from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SplitButton from 'ee/vue_shared/security_reports/components/split_button.vue';
import createState from 'ee/vue_shared/security_reports/store/state';

describe('Security Reports modal footer', () => {
  let wrapper;

  const mountComponent = propsData => {
    wrapper = mount(component, {
      propsData: {
        isCreatingIssue: false,
        isDismissingVulnerability: false,
        isCreatingMergeRequest: false,
        ...propsData,
      },
    });
  };

  describe('can only create issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
      };
      mountComponent(propsData);
    });

    it('does not render dismiss button', () => {
      expect(wrapper.find('.js-dismiss-btn').exists()).toBe(false);
    });

    it('only renders the create issue button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Create issue');
      expect(wrapper.find('.js-action-button').text()).toBe('Create issue');
    });

    it('emits createIssue when create issue button is clicked', () => {
      wrapper.find('.js-action-button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().createNewIssue).toBeTruthy();
      });
    });
  });

  describe('can only create merge request', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateMergeRequest: true,
      };
      mountComponent(propsData);
    });

    it('only renders the create merge request button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Resolve with merge request');
      expect(wrapper.find('.js-action-button').text()).toBe('Resolve with merge request');
    });

    it('emits createMergeRequest when create merge request button is clicked', () => {
      wrapper.find('.js-action-button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().createMergeRequest).toBeTruthy();
      });
    });
  });

  describe('can download download patch', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canDownloadPatch: true,
      };
      mountComponent(propsData);
    });

    it('renders the download patch button', () => {
      expect(wrapper.vm.actionButtons[0].name).toBe('Download patch to resolve');
      expect(wrapper.find('.js-action-button').text()).toBe('Download patch to resolve');
    });

    it('emits downloadPatch when download patch button is clicked', () => {
      wrapper.find('.js-action-button').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().downloadPatch).toBeTruthy();
      });
    });
  });

  describe('can create merge request and issue', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        canCreateMergeRequest: true,
      };
      mountComponent(propsData);
    });

    it('renders create merge request and issue button as a split button', () => {
      expect(wrapper.find('.js-split-button').exists()).toBe(true);
      expect(wrapper.vm.actionButtons).toHaveLength(2);
      expect(wrapper.find(SplitButton).exists()).toBe(true);
      expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
      expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
    });
  });

  describe('can create merge request, issue, and download patch', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canCreateIssue: true,
        canCreateMergeRequest: true,
        canDownloadPatch: true,
      };
      mountComponent(propsData);
    });

    it('renders the split button', () => {
      expect(wrapper.vm.actionButtons).toHaveLength(3);
      expect(wrapper.find(SplitButton).exists()).toBe(true);
      expect(wrapper.find('.js-split-button').text()).toContain('Resolve with merge request');
      expect(wrapper.find('.js-split-button').text()).toContain('Create issue');
      expect(wrapper.find('.js-split-button').text()).toContain('Download patch to resolve');
    });
  });

  describe('with dismissable vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        modal: createState().modal,
        canDismissVulnerability: true,
      };
      mountComponent(propsData);
    });

    it('should render the dismiss button', () => {
      expect(wrapper.find(DismissButton).exists()).toBe(true);
    });
  });
});
