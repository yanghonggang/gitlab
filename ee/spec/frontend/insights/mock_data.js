import { CHART_TYPES } from 'ee/insights/constants';

export const chartInfo = {
  title: 'Bugs Per Team',
  type: CHART_TYPES.BAR,
  query: {
    name: 'filter_issues_by_label_category',
    filter_label: 'bug',
    category_labels: ['Plan', 'Create', 'Manage'],
  },
};

export const barChartData = {
  labels: ['January', 'February'],
  datasets: [
    {
      name: 'all',
      data: [['January', 1], ['February', 2]],
    },
  ],
  xAxisTitle: 'Months',
  yAxisTitle: 'Issues',
};

export const lineChartData = {
  labels: ['January', 'February'],
  datasets: [
    {
      data: [['January', 1], ['February', 2]],
      name: 'Alpha',
    },
    {
      data: [['January', 1], ['February', 2]],
      name: 'Beta',
    },
  ],
  xAxisTitle: 'Months',
  yAxisTitle: 'Issues',
};

export const stackedBarChartData = {
  labels: ['January', 'February'],
  datasets: [
    {
      name: 'Series 1',
      data: [1, 2],
    },
    {
      name: 'Series 2',
      data: [1, 2],
    },
  ],
  xAxisTitle: 'Months',
  yAxisTitle: 'Issues',
};

export const pageInfo = {
  title: 'Title',
  charts: [chartInfo],
};

export const pageInfoNoCharts = {
  page: {
    title: 'Page No Charts',
  },
};

export const configData = {
  example: pageInfo,
  invalid: {
    key: 'key',
  },
};
