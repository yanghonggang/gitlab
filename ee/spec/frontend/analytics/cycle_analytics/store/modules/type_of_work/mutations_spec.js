import { TASKS_BY_TYPE_FILTERS } from 'ee/analytics/cycle_analytics/constants';
import * as types from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/modules/type_of_work/mutations';

import { apiTasksByTypeData, rawTasksByTypeData } from '../../../mock_data';

let state = null;

describe('Value Stream Analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                       | stateKey                       | value
    ${types.REQUEST_TOP_RANKED_GROUP_LABELS}       | ${'topRankedLabels'}           | ${[]}
    ${types.RECEIVE_TOP_RANKED_GROUP_LABELS_ERROR} | ${'topRankedLabels'}           | ${[]}
    ${types.REQUEST_TASKS_BY_TYPE_DATA}            | ${'isLoadingTasksByTypeChart'} | ${true}
    ${types.RECEIVE_TASKS_BY_TYPE_DATA_ERROR}      | ${'isLoadingTasksByTypeChart'} | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation             | payload | expectedState
    ${types.SET_LOADING} | ${true} | ${{ isLoadingTasksByTypeChart: true, isLoadingTasksByTypeChartTopLabels: true }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {};
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS}`, () => {
    it('sets isLoadingTasksByTypeChart to false', () => {
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, {});

      expect(state.isLoadingTasksByTypeChart).toEqual(false);
    });

    it('sets data to the raw returned chart data', () => {
      state = { data: null };
      mutations[types.RECEIVE_TASKS_BY_TYPE_DATA_SUCCESS](state, apiTasksByTypeData);

      expect(state.data).toEqual(rawTasksByTypeData);
    });
  });

  describe(`${types.SET_TASKS_BY_TYPE_FILTERS}`, () => {
    it('will update the tasksByType state key', () => {
      state = {};
      const subjectFilter = { filter: TASKS_BY_TYPE_FILTERS.SUBJECT, value: 'cool-subject' };
      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, subjectFilter);

      expect(state.subject).toEqual('cool-subject');
    });

    it('will toggle the specified label id in the selectedLabelIds state key', () => {
      state = {
        selectedLabelIds: [10, 20, 30],
      };
      const labelFilter = { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: 20 };
      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);

      expect(state.selectedLabelIds).toEqual([10, 30]);

      mutations[types.SET_TASKS_BY_TYPE_FILTERS](state, labelFilter);
      expect(state.selectedLabelIds).toEqual([10, 30, 20]);
    });
  });
});
