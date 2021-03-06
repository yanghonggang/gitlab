<script>
import { GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import NoteHeader from '~/notes/components/note_header.vue';

export default {
  name: 'EventItem',
  components: {
    Icon,
    NoteHeader,
    GlDeprecatedButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    id: {
      type: [String, Number],
      required: false,
      default: undefined,
    },
    author: {
      type: Object,
      required: true,
    },
    createdAt: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: 'plus',
    },
    iconClass: {
      type: String,
      required: false,
      default: 'ci-status-icon-success',
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    showRightSlot: {
      type: Boolean,
      required: false,
      default: false,
    },
    showActionButtons: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    noteId() {
      return this.id ? `note_${this.id}` : undefined;
    },
  },
};
</script>

<template>
  <div :id="noteId" class="d-flex align-items-center">
    <div class="circle-icon-container" :class="iconClass">
      <icon :size="16" :name="iconName" />
    </div>
    <div class="ml-3 flex-grow-1" data-qa-selector="event_item_content">
      <note-header
        :note-id="id"
        :author="author"
        :created-at="createdAt"
        :show-spinner="false"
        class="pb-0"
      >
        <slot name="header-message">&middot;</slot>
      </note-header>

      <slot></slot>
    </div>

    <slot v-if="showRightSlot" name="right-content"></slot>

    <div v-else-if="showActionButtons">
      <gl-deprecated-button
        v-for="button in actionButtons"
        :key="button.title"
        v-gl-tooltip
        class="px-1"
        variant="transparent"
        :title="button.title"
        @click="button.onClick"
      >
        <icon :name="button.iconName" class="link-highlight" />
      </gl-deprecated-button>
    </div>
  </div>
</template>
