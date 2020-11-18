import { GlDropdownItem, GlTruncate } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import FilterItem from 'ee/security_dashboard/components/filters/filter_item.vue';

describe('Filter Item component', () => {
  let wrapper;

  const defaultProps = {
    isChecked: false,
  };

  const createWrapper = (props, slotContent = '') => {
    wrapper = shallowMount(FilterItem, {
      propsData: { ...defaultProps, ...props },
      slots: { default: slotContent },
    });
  };

  const dropdownItem = () => wrapper.find(GlDropdownItem);
  const name = () => wrapper.find(GlTruncate);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('name', () => {
    it('shows the name when the name prop is passed in', () => {
      const text = 'some name';
      createWrapper({ text });
      expect(name().props('text')).toBe(text);
    });

    it('shows slot content when slot content is passed in', () => {
      const slotContent = 'custom slot content';
      createWrapper({}, slotContent);
      expect(name().exists()).toBe(false);
      expect(wrapper.text()).toContain(slotContent);
    });
  });

  it.each([true, false])('shows the expected checkmark when isSelected is %s', isChecked => {
    createWrapper({ isChecked });
    expect(dropdownItem().props('isChecked')).toBe(isChecked);
  });

  it('emits click event when clicked', () => {
    createWrapper();
    dropdownItem().element.click();

    expect(wrapper.emitted('click')).toHaveLength(1);
  });
});
