<script>
import { delay } from 'lodash';

import EpicItemDetails from './epic_item_details.vue';
import EpicItemTimeline from './epic_item_timeline.vue';

import CommonMixin from '../mixins/common_mixin';
import { newDate } from '~/lib/utils/datetime_utility';

import { EPIC_HIGHLIGHT_REMOVE_AFTER, PRESET_TYPES } from '../constants';

export default {
  components: {
    EpicItemDetails,
    EpicItemTimeline,
  },
  mixins: [CommonMixin],
  props: {
    presetType: {
      type: String,
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
    childLevel: {
      type: Number,
      required: true,
    },
    childrenEpics: {
      type: Object,
      required: true,
    },
    childrenFlags: {
      type: Object,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    /**
     * In case Epic start date is out of range
     * we need to use original date instead of proxy date
     */
    startDate() {
      if (this.epic.startDateOutOfRange) {
        return this.epic.originalStartDate;
      }

      return this.epic.startDate;
    },
    /**
     * In case Epic end date is out of range
     * we need to use original date instead of proxy date
     */
    endDate() {
      if (this.epic.endDateOutOfRange) {
        return this.epic.originalEndDate;
      }
      return this.epic.endDate;
    },
    startDateValues() {
      return this.dateValues(this.epic.startDate);
    },
    endDateValues() {
      return this.dateValues(this.epic.endDate);
    },
    /**
     * Find the timeframe index into which the current epic falls
     */
    timeframeIndexForEpic() {
      return this.timeframe.findIndex(eachTimeframe => {
        return this.timeframeHasStartDate(eachTimeframe, this.startDateValues, this.presetType);
      });
    },
    timeframeForEpic() {
      return this.timeframe[this.timeframeIndexForEpic];
    },
    isChildrenEmpty() {
      return this.childrenEpics[this.epic.id] && this.childrenEpics[this.epic.id].length === 0;
    },
    hasChildrenToShow() {
      return this.childrenFlags[this.epic.id].itemExpanded && this.childrenEpics[this.epic.id];
    },
  },
  updated() {
    this.removeHighlight();
  },
  methods: {
    /**
     * When new epics are added to the list on
     * timeline scroll, we set `newEpic` flag
     * as true and then use it in template
     * to set `newly-added-epic` class for
     * highlighting epic using CSS animations
     *
     * Once animation is complete, we need to
     * remove the flag so that animation is not
     * replayed when list is re-rendered.
     */
    removeHighlight() {
      if (this.epic.newEpic) {
        this.$nextTick(() => {
          delay(() => {
            this.epic.newEpic = false;
          }, EPIC_HIGHLIGHT_REMOVE_AFTER);
        });
      }
    },
    dateValues(date) {
      return {
        day: date.getDay(),
        date: date.getDate(),
        month: date.getMonth(),
        year: date.getFullYear(),
        time: date.getTime(),
      };
    },
    /**
     * timeframeHasStartDate is a helper method
     * used to check if the start date of an epic (startDateValues)
     * falls into the given timeframe (timeframeItem).
     */
    timeframeHasStartDate(timeframeItem, startDateValues, presetType) {
      if (presetType === PRESET_TYPES.QUARTERS) {
        const quarterStart = timeframeItem.range[0];
        const quarterEnd = timeframeItem.range[2];

        return (
          startDateValues.time >= quarterStart.getTime() &&
          startDateValues.time <= quarterEnd.getTime()
        );
      } else if (presetType === PRESET_TYPES.MONTHS) {
        return (
          startDateValues.month === timeframeItem.getMonth() &&
          startDateValues.year === timeframeItem.getFullYear()
        );
      } else if (presetType === PRESET_TYPES.WEEKS) {
        const firstDayOfWeek = timeframeItem;
        const lastDayOfWeek = newDate(timeframeItem);
        lastDayOfWeek.setDate(lastDayOfWeek.getDate() + 6);

        return (
          startDateValues.time >= firstDayOfWeek.getTime() &&
          startDateValues.time <= lastDayOfWeek.getTime()
        );
      }
      return false;
    },
  },
};
</script>

<template>
  <div class="epic-item-container">
    <div :class="{ 'newly-added-epic': epic.newEpic }" class="epics-list-item gl-relative clearfix">
      <epic-item-details
        :epic="epic"
        :current-group-id="currentGroupId"
        :timeframe-string="timeframeString(epic)"
        :child-level="childLevel"
        :children-flags="childrenFlags"
        :has-filters-applied="hasFiltersApplied"
        :is-children-empty="isChildrenEmpty"
      />
      <epic-item-timeline
        :preset-type="presetType"
        :start-date-values="startDateValues"
        :end-date-values="endDateValues"
        :timeframe="timeframe"
        :timeframe-item="timeframeForEpic"
        :timeframe-text="timeframeString(epic)"
        :epic="epic"
        :client-width="clientWidth"
      />
    </div>
    <epic-item-container
      v-if="hasChildrenToShow"
      :preset-type="presetType"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      :client-width="clientWidth"
      :children="childrenEpics[epic.id] || []"
      :child-level="childLevel + 1"
      :children-epics="childrenEpics"
      :children-flags="childrenFlags"
      :has-filters-applied="hasFiltersApplied"
    />
  </div>
</template>
