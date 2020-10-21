<script>
import { GlBadge, GlButton, GlTabs, GlTab } from '@gitlab/ui';

import { FilterState } from '../constants';

export default {
  FilterState,
  components: {
    GlBadge,
    GlButton,
    GlTabs,
    GlTab,
  },
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    requirementsCount: {
      type: Object,
      required: true,
    },
    showCreateForm: {
      type: Boolean,
      required: true,
    },
    canCreateRequirement: {
      type: Boolean,
      required: false,
    },
  },
  computed: {
    isOpenTab() {
      return this.filterBy === FilterState.opened;
    },
    isArchivedTab() {
      return this.filterBy === FilterState.archived;
    },
    isAllTab() {
      return this.filterBy === FilterState.all;
    },
  },
};
</script>

<template>
  <gl-tabs class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
    <gl-tab @click="$emit('click-tab', { filterBy: $options.FilterState.opened })">
      <template slot="title">
        <span>{{ __('Open') }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ requirementsCount.OPENED }}</gl-badge>
      </template>
    </gl-tab>
    <gl-tab @click="$emit('click-tab', { filterBy: $options.FilterState.archived })">
      <template slot="title">
        <span>{{ __('Archived') }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ requirementsCount.ARCHIVED }}</gl-badge>
      </template>
    </gl-tab>
    <gl-tab @click="$emit('click-tab', { filterBy: $options.FilterState.all })">
      <template slot="title">
        <span>{{ __('All') }}</span>
        <gl-badge size="sm" class="gl-tab-counter-badge">{{ requirementsCount.ALL }}</gl-badge>
      </template>
    </gl-tab>
    <gl-button
      v-if="isOpenTab && canCreateRequirement"
      category="primary"
      variant="success"
      class="js-new-requirement qa-new-requirement-button"
      :disabled="showCreateForm"
      @click="$emit('click-new-requirement')"
      >{{ __('New requirement') }}</gl-button
    >
  </gl-tabs>
</template>
