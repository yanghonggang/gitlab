<script>
import { GlPopover, GlProgressBar, GlIcon } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { generateKey } from '../utils/epic_utils';

import CommonMixin from '../mixins/common_mixin';
import QuartersPresetMixin from '../mixins/quarters_preset_mixin';
import MonthsPresetMixin from '../mixins/months_preset_mixin';
import WeeksPresetMixin from '../mixins/weeks_preset_mixin';

import {
  EPIC_DETAILS_CELL_WIDTH,
  PERCENTAGE,
  PRESET_TYPES,
  SMALL_TIMELINE_BAR,
  TIMELINE_CELL_MIN_WIDTH,
} from '../constants';

export default {
  cellWidth: TIMELINE_CELL_MIN_WIDTH,
  components: {
    GlIcon,
    GlPopover,
    GlProgressBar,
  },
  mixins: [CommonMixin, QuartersPresetMixin, MonthsPresetMixin, WeeksPresetMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    // startDateValues is used in getTimelineBarWidthFor* mixin methods.
    startDateValues: {
      type: Object,
      required: true,
    },
    // endDateValues is used in getTimelineBarWidthFor* mixin methods.
    endDateValues: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    timeframeItem: {
      type: [Date, Object],
      required: true,
    },
    timeframeText: {
      type: String,
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    timelineBarInnerStyle() {
      return {
        left: `${EPIC_DETAILS_CELL_WIDTH}px`,
        maxWidth: `${this.clientWidth - EPIC_DETAILS_CELL_WIDTH}px`,
      };
    },
    barWidthAndOffset() {
      if (this.presetType === PRESET_TYPES.QUARTERS) {
        return [
          this.getTimelineBarWidthForQuarters(this.epic),
          this.getTimelineBarStartOffsetForQuarters(this.epic, true),
        ];
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        return [
          this.getTimelineBarWidthForMonths(),
          this.getTimelineBarStartOffsetForMonths(this.epic, true),
        ];
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        return [
          this.getTimelineBarWidthForWeeks(),
          this.getTimelineBarStartOffsetForWeeks(this.epic, true),
        ];
      }
      return Infinity;
    },
    barStyle() {
      const [width, offsetWithinFrame] = this.barWidthAndOffset;

      // offsetWithinFrame is in %, convert to px.
      const offset = TIMELINE_CELL_MIN_WIDTH * (offsetWithinFrame / PERCENTAGE);

      const currentFrameIndex = this.timeframe.indexOf(this.timeframeItem);
      const offsetForCurrentFrame = TIMELINE_CELL_MIN_WIDTH * currentFrameIndex;

      /*
        Visual reference
                                                                  <-   width  ->
                                                                  |  epic bar  |
        |       frame 0       |       frame 1       |     current frame    |
        <--         offsetForCurrentFrame        --><-- offset -->
        <--                      left                          -->
      */
      return {
        width: width !== Infinity ? `${width}px` : '',
        left: `${offsetForCurrentFrame + offset}px`,
      };
    },
    isTimelineBarSmall() {
      return this.timelineBarWidth < SMALL_TIMELINE_BAR;
    },
    timelineBarTitle() {
      return this.isTimelineBarSmall ? '...' : this.epic.title;
    },
    epicTotalWeight() {
      if (this.epic.descendantWeightSum) {
        const { openedIssues, closedIssues } = this.epic.descendantWeightSum;
        return openedIssues + closedIssues;
      }
      return undefined;
    },
    epicWeightPercentage() {
      return this.epicTotalWeight
        ? Math.round(
            (this.epic.descendantWeightSum.closedIssues / this.epicTotalWeight) * PERCENTAGE,
          )
        : 0;
    },
    epicWeightPercentageText() {
      return sprintf(__(`%{percentage}%% weight completed`), {
        percentage: this.epicWeightPercentage,
      });
    },
    popoverWeightText() {
      if (this.epic.descendantWeightSum) {
        return sprintf(__('%{completedWeight} of %{totalWeight} weight completed'), {
          completedWeight: this.epic.descendantWeightSum.closedIssues,
          totalWeight: this.epicTotalWeight,
        });
      }
      return __('- of - weight completed');
    },
  },
  methods: {
    generateKey,
  },
};
</script>

<template>
  <span
    class="gl-absolute gl-top-0 gl-bg-transparent gl-h-full"
    :style="{ width: `${this.$options.cellWidth}px` }"
    data-testid="epic-timeline-bar"
    data-qa-selector="epic_timeline_cell"
  >
    <a
      :id="generateKey(epic)"
      :href="epic.webUrl"
      :style="barStyle"
      class="epic-bar gl-absolute gl-z-index-3 gl-rounded-base"
      :class="{ 'epic-bar-child-epic': epic.isChildEpic }"
      data-testid="epic-bar"
    >
      <div class="epic-bar-inner gl-px-3 gl-py-2" :style="timelineBarInnerStyle">
        <p class="epic-bar-title gl-text-truncate gl-m-0">{{ timelineBarTitle }}</p>

        <div v-if="!isTimelineBarSmall" class="gl-display-flex gl-align-items-center">
          <gl-progress-bar
            class="epic-bar-progress gl-flex-grow-1 gl-mr-2"
            :value="epicWeightPercentage"
            aria-hidden="true"
          />
          <div class="gl-font-sm gl-display-flex gl-align-items-center gl-white-space-nowrap">
            <gl-icon class="gl-mr-1" :size="12" name="weight" />
            <p class="gl-m-0" :aria-label="epicWeightPercentageText">{{ epicWeightPercentage }}%</p>
          </div>
        </div>
      </div>
    </a>
    <gl-popover
      :target="generateKey(epic)"
      :title="epic.title"
      triggers="hover"
      placement="lefttop"
    >
      <p class="gl-text-gray-500 gl-m-0">{{ timeframeText }}</p>
      <p class="gl-m-0">{{ popoverWeightText }}</p>
    </gl-popover>
  </span>
</template>
