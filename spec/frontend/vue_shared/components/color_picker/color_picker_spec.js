import { GlFormGroup, GlFormInput, GlFormInputGroup, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import ColorPicker from '~/vue_shared/components/color_picker/color_picker.vue';

describe('ColorPicker', () => {
  let wrapper;

  const createComponent = (fn, propsData) => {
    wrapper = fn(ColorPicker, {
      propsData,
    });
  };

  const setColor = '#000000';
  const label = () => wrapper.find(GlFormGroup).attributes('label');
  const colorPreview = () => wrapper.find('[data-testid="color-preview"]');
  const colorPicker = () => wrapper.find(GlFormInput);
  const colorInput = () => wrapper.find(GlFormInputGroup).find('input[type="text"]');
  const invalidFeedback = () => wrapper.find('.invalid-feedback');
  const description = () => wrapper.find('[data-testid="colors-description"]');
  const presetColors = () => wrapper.findAll(GlLink);

  beforeEach(() => {
    gon.suggested_label_colors = {
      [setColor]: 'Black',
      '#0033CC': 'UA blue',
      '#428BCA': 'Moderate blue',
      '#44AD8E': 'Lime green',
    };

    createComponent(shallowMount);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('label', () => {
    it('hides the label if the label is not passed', () => {
      expect(label()).toBe('');
    });

    it('shows the label if the label is passed', () => {
      createComponent(shallowMount, { label: 'test' });

      expect(label()).toBe('test');
    });
  });

  describe('behavior', () => {
    it('by default has no values', () => {
      createComponent(mount);

      expect(colorPreview().attributes('style')).toBe(undefined);
      expect(colorPicker().attributes('value')).toBe(undefined);
      expect(colorInput().props('value')).toBe('');
    });

    it('has a color set on initialization', () => {
      createComponent(shallowMount, { setColor });

      expect(wrapper.vm.$data.selectedColor).toBe(setColor);
    });

    it('emits input event from component when a color is selected', async () => {
      createComponent(mount);
      await colorInput().setValue(setColor);

      expect(wrapper.emitted().input[0]).toEqual([setColor]);
    });

    it('trims spaces from submitted colors', async () => {
      createComponent(mount);
      await colorInput().setValue(`    ${setColor}    `);

      expect(wrapper.vm.$data.selectedColor).toBe(setColor);
    });

    it('shows invalid feedback when an invalid color is used', async () => {
      createComponent(mount);
      await colorInput().setValue('abcd');

      expect(invalidFeedback().text()).toBe('Please enter a valid HEX color value');
      expect(wrapper.emitted().input).toBe(undefined);
    });
  });

  describe('inputs', () => {
    it('has color input value entered', async () => {
      createComponent(mount);
      await colorInput().setValue(setColor);

      expect(wrapper.vm.$data.selectedColor).toBe(setColor);
    });

    it('has color picker value entered', async () => {
      createComponent(mount);
      await colorPicker().setValue(setColor);

      expect(wrapper.vm.$data.selectedColor).toBe(setColor);
    });
  });

  describe('preset colors', () => {
    it('hides the suggested colors if they are empty', () => {
      gon.suggested_label_colors = {};
      createComponent(shallowMount);

      expect(description().exists()).toBe(false);
      expect(presetColors().exists()).toBe(false);
    });

    it('shows the suggested colors', () => {
      createComponent(mount);
      expect(description().text()).toBe(
        'Choose any color.Or you can choose one of the suggested colors below',
      );
      expect(presetColors()).toHaveLength(4);
    });

    it('has preset color selected', async () => {
      createComponent(mount);
      await presetColors()
        .at(0)
        .trigger('click');

      expect(wrapper.vm.$data.selectedColor).toBe(setColor);
    });
  });
});
