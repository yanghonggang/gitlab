import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import BurnupChart from 'ee/burndown_chart/components/burnup_chart.vue';
import ResizableChartContainer from '~/vue_shared/components/resizable_chart/resizable_chart_container.vue';
import { day1, day2, day3 } from '../mock_data';

describe('Burnup chart', () => {
  let wrapper;

  const defaultProps = {
    startDate: '2019-08-07T00:00:00.000Z',
    dueDate: '2019-09-09T00:00:00.000Z',
  };

  const findChart = () => wrapper.find(GlLineChart);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BurnupChart, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        ResizableChartContainer,
      },
    });
  };

  it('renders the lineChart correctly', () => {
    const burnupData = [day1, day2, day3];

    const expectedScopeCount = [
      [day1.date, day1.scopeCount],
      [day2.date, day2.scopeCount],
      [day3.date, day3.scopeCount],
    ];
    const expectedCompletedCount = [
      [day1.date, day1.completedCount],
      [day2.date, day2.completedCount],
      [day3.date, day3.completedCount],
    ];

    createComponent({ burnupData });
    const chartData = findChart().props('data');

    expect(chartData).toEqual([
      {
        name: 'Total',
        data: expectedScopeCount,
      },
      {
        name: 'Completed',
        data: expectedCompletedCount,
      },
    ]);
  });

  it('only shows integers on axis labels', () => {
    const msInOneDay = 60 * 60 * 24 * 1000;
    expect(findChart().props('option')).toMatchObject({
      xAxis: {
        type: 'time',
        minInterval: msInOneDay,
      },
      yAxis: {
        minInterval: 1,
      },
    });
  });

  it('does not show average or max values in legend', () => {
    expect(findChart().props('includeLegendAvgMax')).toBe(false);
  });
});
