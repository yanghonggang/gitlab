import { GlEmptyState } from '@gitlab/ui';
import { GlColumnChart } from '@gitlab/ui/dist/charts';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';

import InsightsChart from 'ee/insights/components/insights_chart.vue';
import InsightsPage from 'ee/insights/components/insights_page.vue';
import { createStore } from 'ee/insights/stores';
import { chartInfo, pageInfo, pageInfoNoCharts, barChartData } from 'ee_jest/insights/mock_data';
import { TEST_HOST } from 'helpers/test_constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Insights page component', () => {
  let store;
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(InsightsPage, {
      localVue,
      store,
      propsData: {
        queryEndpoint: `${TEST_HOST}/query`,
        pageConfig: pageInfoNoCharts,
        ...props,
      },
    });
  };

  const createLoadingChartData = () => {
    return pageInfo.charts.reduce((memo, chart) => {
      return { ...memo, [chart.title]: {} };
    }, {});
  };

  const createLoadedChartData = () => {
    return pageInfo.charts.reduce((memo, chart) => {
      return {
        ...memo,
        [chart.title]: {
          loaded: true,
          type: chart.type,
          description: '',
          data: barChartData,
          error: null,
        },
      };
    }, {});
  };

  const findInsightsChartData = () => wrapper.find(InsightsChart);

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('no chart config available', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not fetch chart data when mounted', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('shows an empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('charts configured', () => {
    beforeEach(() => {
      createComponent({ pageConfig: pageInfo });
    });

    it('fetches chart data when mounted', () => {
      expect(store.dispatch).toHaveBeenCalledWith('insights/fetchChartData', {
        endpoint: `${TEST_HOST}/query`,
        chart: chartInfo,
      });
    });

    it('does not show empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    });

    describe('pageConfig changes', () => {
      it('reflects new state', async () => {
        wrapper.setProps({ pageConfig: pageInfoNoCharts });

        await wrapper.vm.$nextTick();

        expect(wrapper.find(GlEmptyState).exists()).toBe(true);
      });
    });

    describe('when charts loading', () => {
      beforeEach(() => {
        store.state.insights.chartData = createLoadingChartData();
      });

      it('renders loading state', () => {
        expect(findInsightsChartData().props()).toMatchObject({
          loaded: false,
        });
      });

      it('does not display chart', () => {
        expect(wrapper.find(GlColumnChart).exists()).toBe(false);
      });
    });

    describe('charts configured and loaded', () => {
      beforeEach(() => {
        store.state.insights.chartData = createLoadedChartData();
      });

      it('does not render loading state', () => {
        expect(findInsightsChartData().props()).toMatchObject({
          loaded: true,
        });
      });
    });
  });
});
