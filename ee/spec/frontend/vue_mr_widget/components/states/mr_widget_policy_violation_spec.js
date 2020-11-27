import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrWidgetPolicyViolation from 'ee/vue_merge_request_widget/components/states/mr_widget_policy_violation.vue';

describe('EE MrWidgetPolicyViolation', () => {
  let wrapper;

  const findButton = () => wrapper.find(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(MrWidgetPolicyViolation, {});
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('shows the disabled merge button', () => {
    expect(wrapper.text()).toContain('Merge');
    expect(findButton().props().disabled).toBe(true);
  });

  it('shows the disabled reason', () => {
    expect(wrapper.text()).toContain('You can merge after removing denied licenses');
  });
});
