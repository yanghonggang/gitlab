<script>
import { GlDropdown, GlDropdownForm, GlFormTextarea, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: { GlDropdown, GlDropdownForm, GlFormTextarea, GlButton },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBatch: {
      type: Boolean,
      required: false,
      default: false,
    },
    filePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      message: null,
      buttonText: this.isBatch ? __('Add suggestion to batch') : __('Apply suggestion'),
    };
  },
  computed: {
    placeholderText() {
      return sprintf(__('Apply suggestion on %{filePath}'), { filePath: this.filePath });
    },
  },
  methods: {
    onApply() {
      this.$emit('apply', this.message || this.placeholderText);
    },
  },
};
</script>

<template>
  <gl-dropdown
    :text="buttonText"
    :disabled="disabled"
    boundary="window"
    :right="true"
    menu-class="gl-w-full!"
  >
    <gl-dropdown-form class="gl-px-4! gl-m-0!">
      <label for="commit-message">{{ __('Commit message') }}</label>
      <gl-form-textarea id="commit-message" v-model="message" :placeholder="placeholderText" />
      <gl-button
        class="gl-w-auto! gl-mt-3 gl-text-center! float-right"
        category="primary"
        variant="success"
        @click="onApply"
      >
        {{ isBatch ? __('Add') : __('Apply') }}
      </gl-button>
    </gl-dropdown-form>
  </gl-dropdown>
</template>
