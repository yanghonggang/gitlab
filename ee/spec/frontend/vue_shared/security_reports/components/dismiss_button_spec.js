import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import component from 'ee/vue_shared/security_reports/components/dismiss_button.vue';

describe('DismissalButton', () => {
  let wrapper;

  const mountComponent = options => {
    wrapper = mount(component, options);
  };

  describe('With a non-dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: false,
      };
      mountComponent({ propsData });
    });

    it('should render the dismiss button', () => {
      expect(wrapper.text()).toBe('Dismiss vulnerability');
    });

    it('should emit dismiss vulnerability when clicked', () => {
      wrapper.find(GlButton).trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().dismissVulnerability).toBeTruthy();
      });
    });

    it('should render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(true);
    });

    it('should emit openDismissalCommentBox when clicked', () => {
      wrapper.find('.js-dismiss-with-comment').trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().openDismissalCommentBox).toBeTruthy();
      });
    });
  });

  describe('with a dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: true,
      };
      mountComponent({ propsData });
    });

    it('should render the undo dismiss button', () => {
      expect(wrapper.text()).toBe('Undo dismiss');
    });

    it('should emit revertDismissVulnerability when clicked', () => {
      wrapper.find(GlButton).trigger('click');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().revertDismissVulnerability).toBeTruthy();
      });
    });

    it('should not render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(false);
    });
  });
});
