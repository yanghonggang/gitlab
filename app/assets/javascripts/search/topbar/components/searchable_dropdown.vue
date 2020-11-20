<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlIcon,
  GlButton,
  GlSkeletonLoader,
  GlTooltipDirective,
} from '@gitlab/ui';

import { ANY_GROUP_OR_PROJECT } from '../constants';

export default {
  name: 'SearchableDropdown',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlIcon,
    GlButton,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    headerText: {
      type: String,
      required: false,
      default: `__('Filter')`,
    },
    selectedDisplayValue: {
      type: String,
      required: false,
      default: 'name',
    },
    itemsDisplayValue: {
      type: String,
      required: false,
      default: 'name',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedItem: {
      type: Object,
      required: true,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      searchText: '',
    };
  },
  methods: {
    isSelected(selected) {
      return selected.id === this.selectedItem.id;
    },
    openDropdown() {
      this.$emit('search', this.searchText);
    },
  },
  ANY_GROUP_OR_PROJECT,
};
</script>

<template>
  <gl-dropdown
    class="gl-w-full"
    menu-class="gl-w-full!"
    toggle-class="gl-text-truncate gl-reset-line-height!"
    :header-text="headerText"
    @show="$emit('search', searchText)"
    @shown="$refs.searchBox.focusInput()"
  >
    <template #button-content>
      <span class="dropdown-toggle-text gl-flex-grow-1 gl-text-truncate">
        {{ selectedItem[selectedDisplayValue] }}
      </span>
      <gl-loading-icon v-if="loading" inline class="gl-mr-3" />
      <gl-button
        v-if="!isSelected($options.ANY_GROUP_OR_PROJECT)"
        v-gl-tooltip
        category="tertiary"
        :title="__('Clear')"
        class="gl-p-0! gl-mr-2"
        @keydown.enter.stop="$emit('change', $options.ANY_GROUP_OR_PROJECT)"
        @click.stop="$emit('change', $options.ANY_GROUP_OR_PROJECT)"
      >
        <gl-icon name="clear" class="gl-text-gray-200! gl-hover-text-blue-800!" />
      </gl-button>
      <gl-icon name="chevron-down" />
    </template>
    <div class="gl-sticky gl-top-0 gl-z-index-1 gl-bg-white">
      <gl-search-box-by-type
        ref="searchBox"
        v-model="searchText"
        class="gl-m-3"
        :debounce="500"
        @input="$emit('search', searchText)"
      />
      <gl-dropdown-item
        class="gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2"
        :is-check-item="true"
        :is-checked="isSelected($options.ANY_GROUP_OR_PROJECT)"
        @click="$emit('change', $options.ANY_GROUP_OR_PROJECT)"
      >
        {{ $options.ANY_GROUP_OR_PROJECT.name }}
      </gl-dropdown-item>
    </div>
    <div v-if="!loading">
      <gl-dropdown-item
        v-for="item in items"
        :key="item.id"
        :is-check-item="true"
        :is-checked="isSelected(item)"
        @click="$emit('change', item)"
      >
        {{ item[itemsDisplayValue] }}
      </gl-dropdown-item>
    </div>
    <div v-if="loading" class="gl-mx-4 gl-mt-3">
      <gl-skeleton-loader :height="100">
        <rect y="0" width="90%" height="20" rx="4" />
        <rect y="40" width="70%" height="20" rx="4" />
        <rect y="80" width="80%" height="20" rx="4" />
      </gl-skeleton-loader>
    </div>
  </gl-dropdown>
</template>
