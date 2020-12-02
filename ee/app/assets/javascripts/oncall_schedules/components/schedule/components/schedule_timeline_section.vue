<script>
import { GlCard, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import WeeksHeaderItem from './preset_weeks/weeks_header_item.vue';

export const i18n = {
  rotationTitle: s__('OnCallSchedules|Rotations'),
  addARotation: s__('OnCallSchedules|Add a rotation'),
};

export default {
  i18n,
  components: {
    GlButton,
    GlCard,
    WeeksHeaderItem,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <gl-card header-class="gl-bg-transparent">
    <template #header>
      <div class="gl-display-flex gl-justify-content-space-between">
        <span class="gl-font-weight-bold gl-font-lg"> {{ $options.i18n.rotationTitle }} </span>
        <gl-button variant="link"> {{ $options.i18n.addARotation }}</gl-button>
      </div>
    </template>

    <div class="timeline-section clearfix">
      <span class="timeline-header-blank"></span>
      <weeks-header-item
        v-for="(timeframeItem, index) in timeframe"
        :key="index"
        :timeframe-index="index"
        :timeframe-item="timeframeItem"
        :timeframe="timeframe"
      />
    </div>
  </gl-card>
</template>
