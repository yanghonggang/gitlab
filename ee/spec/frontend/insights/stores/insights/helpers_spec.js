import { CHART_TYPES } from 'ee/insights/constants';
import { transformChartDataForGlCharts } from 'ee/insights/stores/modules/insights/helpers';

describe('Insights helpers', () => {
  describe('transformChartDataForGlCharts', () => {
    it('sets the x axis label to "Months"', () => {
      const chart = {
        type: CHART_TYPES.BAR,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ label: 'Dataset 1', data: [1] }, { label: 'Dataset 2', data: [2] }],
      };

      expect(transformChartDataForGlCharts(chart, data).xAxisTitle).toEqual('Months');
    });

    it('sets the y axis label to "Issues"', () => {
      const chart = {
        type: CHART_TYPES.BAR,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ label: 'Dataset 1', data: [1] }, { label: 'Dataset 2', data: [2] }],
      };

      expect(transformChartDataForGlCharts(chart, data).yAxisTitle).toEqual('Issues');
    });

    it('copies the data to the datasets for stacked bar charts', () => {
      const chart = {
        type: CHART_TYPES.STACKED_BAR,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ label: 'Dataset 1', data: [1] }, { label: 'Dataset 2', data: [2] }],
      };

      expect(transformChartDataForGlCharts(chart, data).datasets).toEqual([
        { name: 'Dataset 1', data: [1] },
        { name: 'Dataset 2', data: [2] },
      ]);
    });

    it('creates an array of objects containing name and data attributes for line charts', () => {
      const chart = {
        type: CHART_TYPES.LINE,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ label: 'Dataset 1', data: [1, 2] }, { label: 'Dataset 2', data: [2, 3] }],
      };

      expect(transformChartDataForGlCharts(chart, data).datasets).toStrictEqual([
        { name: 'Dataset 1', data: [['January', 1], ['February', 2]] },
        { name: 'Dataset 2', data: [['January', 2], ['February', 3]] },
      ]);
    });

    it('creates an array of objects containing an array of label / data pairs and a name for bar charts', () => {
      const chart = {
        type: CHART_TYPES.BAR,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ data: [1, 2] }],
      };

      expect(transformChartDataForGlCharts(chart, data).datasets).toEqual([
        { name: 'all', data: [['January', 1], ['February', 2]] },
      ]);
    });

    it('creates an object of all containing an array of label / data pairs for pie charts', () => {
      const chart = {
        type: CHART_TYPES.PIE,
        query: { group_by: 'month', issuable_type: 'issue' },
      };
      const data = {
        labels: ['January', 'February'],
        datasets: [{ data: [1, 2] }],
      };

      expect(transformChartDataForGlCharts(chart, data).datasets).toEqual({
        all: [['January', 1], ['February', 2]],
      });
    });
  });
});
