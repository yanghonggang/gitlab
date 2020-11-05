import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { GlIcon } from '@gitlab/ui';
import TooltipIcon from 'ee/security_configuration/dast_scanner_profiles/components/tooltip_icon.vue';

describe('Tooltip Icon', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const title = 'Hello world';

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TooltipIcon, {
      propsData: {
        title,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders icon correctly', () => {
    expect(findIcon().exists()).toBe(true);
  });

  it('renders tooltip correctly', () => {
    const tooltip = getBinding(findIcon().element, 'gl-tooltip').value;
    expect(tooltip).toBeDefined();
    expect(tooltip).toBe(title);
  });
});
