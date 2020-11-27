import { GlAlert } from '@gitlab/ui';
import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ThroughputChart from 'ee/analytics/merge_request_analytics/components/throughput_chart.vue';
import { THROUGHPUT_CHART_STRINGS } from 'ee/analytics/merge_request_analytics/constants';
import store from 'ee/analytics/merge_request_analytics/store';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';
import {
  throughputChartData,
  throughputChartNoData,
  startDate,
  endDate,
  fullPath,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const defaultQueryVariables = {
  assigneeUsername: null,
  authorUsername: null,
  milestoneTitle: null,
  labels: null,
};

const defaultMocks = {
  $apollo: {
    queries: {
      throughputChartData: {},
    },
  },
};

describe('ThroughputChart', () => {
  let wrapper;

  function displaysComponent(component, visible) {
    const element = wrapper.find(component);

    expect(element.exists()).toBe(visible);
  }

  function createComponent(options = {}) {
    const { mocks = defaultMocks } = options;
    return shallowMount(ThroughputChart, {
      localVue,
      store,
      mocks,
      provide: {
        fullPath,
      },
      props: {
        startDate,
        endDate,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays the chart title', () => {
      const chartTitle = wrapper.find('[data-testid="chartTitle"').text();

      expect(chartTitle).toBe(THROUGHPUT_CHART_STRINGS.CHART_TITLE);
    });

    it('displays the chart description', () => {
      const chartDescription = wrapper.find('[data-testid="chartDescription"').text();

      expect(chartDescription).toBe(THROUGHPUT_CHART_STRINGS.CHART_DESCRIPTION);
    });

    it('displays an empty state message when there is no data', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.NO_DATA);
    });

    it('does not display a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });
  });

  describe('while loading', () => {
    const apolloLoading = {
      queries: {
        throughputChartData: {
          loading: true,
        },
      },
    };

    beforeEach(() => {
      wrapper = createComponent({ mocks: { ...defaultMocks, $apollo: apolloLoading } });
    });

    it('displays a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, true);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('does not display a no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.setData({ throughputChartData });
    });

    it('displays the chart', () => {
      displaysComponent(GlAreaChart, true);
    });

    it('does not display the skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display a no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with no data in the response', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.setData({ throughputChartData: throughputChartNoData });
    });

    it('does not display a skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('displays an empty state message when there is no data', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.NO_DATA);
    });
  });

  describe('with errors', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.setData({ hasError: true });
    });

    it('does not display the chart', () => {
      displaysComponent(GlAreaChart, false);
    });

    it('does not display the skeleton loader', () => {
      displaysComponent(ChartSkeletonLoader, false);
    });

    it('displays an error message', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_CHART_STRINGS.ERROR_FETCHING_DATA);
    });
  });

  describe('when fetching data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has initial variables set', () => {
      expect(
        wrapper.vm.$options.apollo.throughputChartData.variables.bind(wrapper.vm)(),
      ).toMatchObject(defaultQueryVariables);
    });

    it('gets filter variables from store', async () => {
      const operator = '=';
      const assigneeUsername = 'foo';
      const authorUsername = 'bar';
      const milestoneTitle = 'baz';
      const labels = ['quis', 'quux'];

      wrapper.vm.$store.dispatch('filters/initialize', {
        selectedAssignee: { value: assigneeUsername, operator },
        selectedAuthor: { value: authorUsername, operator },
        selectedMilestone: { value: milestoneTitle, operator },
        selectedLabelList: [{ value: labels[0], operator }, { value: labels[1], operator }],
      });
      await wrapper.vm.$nextTick();
      expect(
        wrapper.vm.$options.apollo.throughputChartData.variables.bind(wrapper.vm)(),
      ).toMatchObject({
        assigneeUsername,
        authorUsername,
        milestoneTitle,
        labels,
      });
    });
  });
});
