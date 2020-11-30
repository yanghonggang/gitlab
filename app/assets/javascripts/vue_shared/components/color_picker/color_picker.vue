<script>
/**
 * Renders a color picker input with preset colors to choose from
 *
 * @example
 * <color-picker :label="__('Background color')" set-color="#FF0000" />
 */
import {
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';

const COLOR_VALID = /^#([0-9A-F]{3}){1,2}$/i;

export default {
  name: 'ColorPicker',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: '',
    },
    setColor: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selectedColor: this.setColor.trim() || '',
    };
  },
  computed: {
    description() {
      return this.$options.i18n.description;
    },
    suggestedColors() {
      const colorsMap = gon.suggested_label_colors;
      return Object.keys(colorsMap).map(color => ({ [color]: colorsMap[color] }));
    },
    previewColor() {
      if (this.isValidColor) {
        return { backgroundColor: this.selectedColor };
      }

      return {};
    },
    hasSuggestedColors() {
      return this.suggestedColors.length;
    },
    isValidColor() {
      if (this.selectedColor === '') {
        return null;
      }

      return COLOR_VALID.test(this.selectedColor);
    },
  },
  watch: {
    selectedColor() {
      if (this.isValidColor) {
        this.$emit('input', this.selectedColor);
      }
    },
  },
  methods: {
    getColorCode(color) {
      return Object.keys(color)[0];
    },
    getColorName(color) {
      return Object.values(color)[0];
    },
    handleColorChange(color) {
      this.selectedColor = color.trim();
    },
  },
  i18n: {
    description: s__(
      '%{lineStart}Choose any color.%{lineEnd}%{lineStart}Or you can choose one of the suggested colors below%{lineEnd}',
    ),
    invalid: __('Please enter a valid HEX color value'),
  },
};
</script>

<template>
  <div>
    <gl-form-group :label="label" label-for="color-picker" :invalid-feedback="this.$options.i18n.invalid" :state="isValidColor">
      <gl-form-input-group
        id="color-picker"
        type="text"
        class="gl-align-center gl-rounded-0 gl-rounded-top-right-base gl-rounded-bottom-right-base"
        v-model.trim="selectedColor"
      >
        <template #prepend>
          <div
            class="gl-relative gl-align-center gl-w-7 gl-overflow-hidden gl-border-solid gl-border-1 gl-border-r-0! gl-border-gray-400 gl-rounded-top-left-base gl-rounded-bottom-left-base"
          >
            <span
              class="gl-w-full gl-h-full gl-absolute gl-top-0 gl-left-0 gl-bg-gray-10"
              data-testid="color-preview"
              :style="previewColor"
              tabindex="-1"
              aria-hidden="true"
            ></span>
            <gl-form-input
              type="color"
              class="gl-absolute gl-top-0 gl-left-0 gl-h-full! gl-p-0! gl-m-0! gl-cursor-pointer gl-opacity-0"
              tabindex="-1"
              aria-hidden="true"
              :value="selectedColor"
              @input="handleColorChange"
            />
          </div>
        </template>
      </gl-form-input-group>

      <template #description>
        <span
          v-if="hasSuggestedColors"
          data-testid="colors-description"
        >
          <gl-sprintf :message="description">
            <template #line="{ content }">
              <span class="gl-display-block">{{ content }}</span>
            </template>
          </gl-sprintf>
        </span>
      </template>
    </gl-form-group>

    <div v-if="hasSuggestedColors" class="gl-mb-3">
      <gl-link
        v-for="(color, index) in suggestedColors"
        :key="index"
        v-gl-tooltip:tooltipcontainer
        :title="getColorName(color)"
        :style="{ backgroundColor: getColorCode(color) }"
        class="gl-rounded-base gl-w-7 gl-h-7 gl-display-inline-block gl-mr-3 gl-mb-3 gl-text-decoration-none"
        @click.prevent="handleColorChange(getColorCode(color))"
      />
    </div>
  </div>
</template>
