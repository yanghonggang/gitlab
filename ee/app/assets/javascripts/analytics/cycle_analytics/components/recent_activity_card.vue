<script>
import Api from 'ee/api';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import MetricCard from '../../shared/components/metric_card.vue';
import { removeFlash } from '../utils';

export default {
  name: 'RecentActivityCard',
  components: {
    MetricCard,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    additionalParams: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      data: [],
      loading: false,
    };
  },
  watch: {
    additionalParams() {
      this.fetchData();
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      removeFlash();
      this.loading = true;
      return Api.cycleAnalyticsSummaryData(
        this.groupPath,
        this.additionalParams ? this.additionalParams : {},
      )
        .then(({ data }) => {
          this.data = data.map(({ title: label, value }) => ({
            value: value || '-',
            label,
            key: slugify(label),
          }));
        })
        .catch(() => {
          createFlash(
            __('There was an error while fetching value stream analytics recent activity data.'),
          );
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>
<template>
  <metric-card :title="__('Recent Activity')" :metrics="data" :is-loading="loading" />
</template>
