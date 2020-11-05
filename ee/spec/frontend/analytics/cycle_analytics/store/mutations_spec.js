import mutations from 'ee/analytics/cycle_analytics/store/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/mutation_types';

import {
  issueStage,
  planStage,
  codeStage,
  stagingStage,
  reviewStage,
  startDate,
  endDate,
  selectedProjects,
  customizableStagesAndEvents,
  valueStreams,
} from '../mock_data';

let state = null;

describe('Value Stream Analytics mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                     | stateKey                     | value
    ${types.REQUEST_VALUE_STREAMS}               | ${'valueStreams'}            | ${[]}
    ${types.RECEIVE_VALUE_STREAMS_ERROR}         | ${'valueStreams'}            | ${[]}
    ${types.REQUEST_VALUE_STREAMS}               | ${'isLoadingValueStreams'}   | ${true}
    ${types.RECEIVE_VALUE_STREAMS_ERROR}         | ${'isLoadingValueStreams'}   | ${false}
    ${types.REQUEST_STAGE_DATA}                  | ${'isLoadingStage'}          | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}            | ${'isEmptyStage'}            | ${true}
    ${types.RECEIVE_STAGE_DATA_ERROR}            | ${'isLoadingStage'}          | ${false}
    ${types.REQUEST_CYCLE_ANALYTICS_DATA}        | ${'isLoading'}               | ${true}
    ${types.RECEIVE_GROUP_STAGES_ERROR}          | ${'stages'}                  | ${[]}
    ${types.REQUEST_GROUP_STAGES}                | ${'stages'}                  | ${[]}
    ${types.REQUEST_UPDATE_STAGE}                | ${'isLoading'}               | ${true}
    ${types.RECEIVE_UPDATE_STAGE_SUCCESS}        | ${'isLoading'}               | ${false}
    ${types.RECEIVE_UPDATE_STAGE_ERROR}          | ${'isLoading'}               | ${false}
    ${types.REQUEST_REMOVE_STAGE}                | ${'isLoading'}               | ${true}
    ${types.RECEIVE_REMOVE_STAGE_RESPONSE}       | ${'isLoading'}               | ${false}
    ${types.REQUEST_STAGE_MEDIANS}               | ${'medians'}                 | ${{}}
    ${types.RECEIVE_STAGE_MEDIANS_ERROR}         | ${'medians'}                 | ${{}}
    ${types.REQUEST_CREATE_VALUE_STREAM}         | ${'isCreatingValueStream'}   | ${true}
    ${types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS} | ${'isCreatingValueStream'}   | ${false}
    ${types.REQUEST_CREATE_VALUE_STREAM}         | ${'createValueStreamErrors'} | ${{}}
    ${types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS} | ${'createValueStreamErrors'} | ${{}}
    ${types.REQUEST_DELETE_VALUE_STREAM}         | ${'isDeletingValueStream'}   | ${true}
    ${types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS} | ${'isDeletingValueStream'}   | ${false}
    ${types.REQUEST_DELETE_VALUE_STREAM}         | ${'deleteValueStreamError'}  | ${null}
    ${types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS} | ${'deleteValueStreamError'}  | ${null}
    ${types.RECEIVE_DELETE_VALUE_STREAM_SUCCESS} | ${'selectedValueStream'}     | ${null}
    ${types.INITIALIZE_CYCLE_ANALYTICS_SUCCESS}  | ${'isLoading'}               | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                                     | payload                                  | expectedState
    ${types.SET_FEATURE_FLAGS}                   | ${{ hasDurationChart: true }}            | ${{ featureFlags: { hasDurationChart: true } }}
    ${types.SET_SELECTED_PROJECTS}               | ${selectedProjects}                      | ${{ selectedProjects }}
    ${types.SET_DATE_RANGE}                      | ${{ startDate, endDate }}                | ${{ startDate, endDate }}
    ${types.SET_SELECTED_STAGE}                  | ${{ id: 'first-stage' }}                 | ${{ selectedStage: { id: 'first-stage' } }}
    ${types.RECEIVE_CREATE_VALUE_STREAM_ERROR}   | ${{ errors: { name: ['is required'] } }} | ${{ createValueStreamErrors: { name: ['is required'] }, isCreatingValueStream: false }}
    ${types.RECEIVE_DELETE_VALUE_STREAM_ERROR}   | ${'Some error occurred'}                 | ${{ deleteValueStreamError: 'Some error occurred' }}
    ${types.RECEIVE_VALUE_STREAMS_SUCCESS}       | ${valueStreams}                          | ${{ valueStreams, isLoadingValueStreams: false }}
    ${types.SET_SELECTED_VALUE_STREAM}           | ${valueStreams[1].id}                    | ${{ selectedValueStream: {} }}
    ${types.RECEIVE_CREATE_VALUE_STREAM_SUCCESS} | ${valueStreams[1]}                       | ${{ selectedValueStream: valueStreams[1] }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = { selectedGroup: { fullPath: 'rad-stage' } };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_VALUE_STREAMS_SUCCESS}`, () => {
    const dummyValueStream = { id: 3, name: 'A new value stream' };
    const sorted = [dummyValueStream, valueStreams[0], valueStreams[1]];
    it('will sort the value streams alphabetically', () => {
      state = { valueStreams: [] };
      mutations[types.RECEIVE_VALUE_STREAMS_SUCCESS](state, [
        valueStreams[1],
        valueStreams[0],
        dummyValueStream,
      ]);

      expect(state.valueStreams).toEqual(sorted);
    });
  });

  describe('with value streams available', () => {
    it.each`
      mutation                           | payload            | expectedState
      ${types.SET_SELECTED_VALUE_STREAM} | ${valueStreams[1]} | ${{ selectedValueStream: valueStreams[1] }}
      ${types.SET_SELECTED_VALUE_STREAM} | ${'fake-id'}       | ${{ selectedValueStream: {} }}
    `(
      '$mutation with payload $payload will update state with $expectedState',
      ({ mutation, payload, expectedState }) => {
        state = { valueStreams };
        mutations[mutation](state, payload);
        expect(state).toMatchObject(expectedState);
      },
    );
  });

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS}`, () => {
    it('will set isLoading=false and errorCode=null', () => {
      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, {
        stats: [],
        stages: [],
      });

      expect(state.errorCode).toBe(null);
      expect(state.isLoading).toBe(false);
    });
  });

  describe(`${types.RECEIVE_GROUP_STAGES_SUCCESS}`, () => {
    describe('with data', () => {
      beforeEach(() => {
        mutations[types.RECEIVE_GROUP_STAGES_SUCCESS](state, customizableStagesAndEvents.stages);
      });

      it('will convert the stats object to stages', () => {
        [issueStage, planStage, codeStage, stagingStage, reviewStage].forEach(stage => {
          expect(state.stages).toContainEqual(stage);
        });
      });
    });
  });

  describe(`${types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR}`, () => {
    it('sets errorCode correctly', () => {
      const errorCode = 403;

      mutations[types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state, errorCode);

      expect(state.isLoading).toBe(false);
      expect(state.errorCode).toBe(errorCode);
    });
  });

  describe(`${types.RECEIVE_STAGE_MEDIANS_SUCCESS}`, () => {
    it('sets each id as a key in the median object with the corresponding value and error', () => {
      const stateWithData = {
        medians: {},
      };

      mutations[types.RECEIVE_STAGE_MEDIANS_SUCCESS](stateWithData, [
        { id: 1, value: 20 },
        { id: 2, value: 10 },
      ]);

      expect(stateWithData.medians).toEqual({
        '1': { value: 20, error: null },
        '2': { value: 10, error: null },
      });
    });
  });

  describe(`${types.INITIALIZE_CYCLE_ANALYTICS}`, () => {
    const initialData = {
      group: { fullPath: 'cool-group' },
      selectedProjects,
      createdAfter: '2019-12-31',
      createdBefore: '2020-01-01',
    };

    it.each`
      stateKey              | expectedState
      ${'isLoading'}        | ${true}
      ${'selectedProjects'} | ${initialData.selectedProjects}
      ${'startDate'}        | ${initialData.createdAfter}
      ${'endDate'}          | ${initialData.createdBefore}
    `(
      '$mutation with payload $payload will update state with $expectedState',
      ({ stateKey, expectedState }) => {
        state = {};
        mutations[types.INITIALIZE_CYCLE_ANALYTICS](state, initialData);

        expect(state[stateKey]).toEqual(expectedState);
      },
    );
  });
});
