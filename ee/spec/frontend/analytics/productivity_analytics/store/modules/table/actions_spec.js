import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/analytics/productivity_analytics/store/modules/table/actions';
import * as types from 'ee/analytics/productivity_analytics/store/modules/table/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/modules/table/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { mockMergeRequests } from '../../../mock_data';

describe('Productivity analytics table actions', () => {
  let mockedContext;
  let mockedState;
  let mock;

  const groupNamespace = 'gitlab-org';
  const projectPath = 'gitlab-org/gitlab-test';

  const filterParams = {
    days_to_merge: [5],
    sort: 'time_to_merge_asc',
  };

  const pageInfo = {
    page: 1,
    nextPage: 2,
    previousPage: 1,
    perPage: 10,
    total: 50,
    totalPages: 5,
  };

  const headers = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Per-Page': pageInfo.perPage,
    'X-Prev-Page': pageInfo.previousPage,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  beforeEach(() => {
    mockedContext = {
      dispatch() {},
      rootState: {
        charts: {
          charts: {
            main: {
              selected: [5],
            },
          },
        },
        endpoint: `${TEST_HOST}/analytics/productivity_analytics.json`,
      },
      getters: {
        getFilterParams: () => filterParams,
      },
      rootGetters: {
        // eslint-disable-next-line no-useless-computed-key
        ['filters/getCommonFilterParams']: () => {
          const params = {
            group_id: groupNamespace,
            project_id: projectPath,
          };
          return params;
        },
      },
      state: getInitialState(),
    };

    // testAction looks for rootGetters in state,
    // so they need to be concatenated here.
    mockedState = {
      ...mockedContext.state,
      ...mockedContext.getters,
      ...mockedContext.rootGetters,
      ...mockedContext.rootState,
    };

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchMergeRequests', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(200, mockMergeRequests, headers);
      });

      it('calls API with pparams', () => {
        jest.spyOn(axios, 'get');

        actions.fetchMergeRequests(mockedContext);

        expect(axios.get).toHaveBeenCalledWith(mockedState.endpoint, {
          params: {
            group_id: groupNamespace,
            project_id: projectPath,
            days_to_merge: [5],
            sort: 'time_to_merge_asc',
          },
        });
      });

      it('dispatches success with received data', done =>
        testAction(
          actions.fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            {
              type: 'receiveMergeRequestsSuccess',
              payload: { data: mockMergeRequests, headers },
            },
          ],
          done,
        ));
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(mockedState.endpoint).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          actions.fetchMergeRequests,
          null,
          mockedState,
          [],
          [
            { type: 'requestMergeRequests' },
            {
              type: 'receiveMergeRequestsError',
              payload: new Error('Request failed with status code 500'),
            },
          ],
          done,
        );
      });
    });
  });

  describe('requestMergeRequests', () => {
    it('should commit the request mutation', done =>
      testAction(
        actions.requestMergeRequests,
        null,
        mockedContext.state,
        [{ type: types.REQUEST_MERGE_REQUESTS }],
        [],
        done,
      ));
  });

  describe('receiveMergeRequestsSuccess', () => {
    it('should commit received data', done =>
      testAction(
        actions.receiveMergeRequestsSuccess,
        { headers, data: mockMergeRequests },
        mockedContext.state,
        [
          {
            type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
            payload: { pageInfo, mergeRequests: mockMergeRequests },
          },
        ],
        [],
        done,
      ));
  });

  describe('receiveMergeRequestsError', () => {
    it('should commit error', done =>
      testAction(
        actions.receiveMergeRequestsError,
        { response: { status: 500 } },
        mockedContext.state,
        [{ type: types.RECEIVE_MERGE_REQUESTS_ERROR, payload: 500 }],
        [],
        done,
      ));
  });

  describe('setSortField', () => {
    it('should commit setSortField', done =>
      testAction(
        actions.setSortField,
        'time_to_last_commit',
        mockedContext.state,
        [{ type: types.SET_SORT_FIELD, payload: 'time_to_last_commit' }],
        [
          { type: 'setColumnMetric', payload: 'time_to_last_commit' },
          { type: 'fetchMergeRequests' },
        ],
        done,
      ));

    it('should not dispatch setColumnMetric when metric is "days_to_merge"', done =>
      testAction(
        actions.setSortField,
        'days_to_merge',
        mockedContext.state,
        [{ type: types.SET_SORT_FIELD, payload: 'days_to_merge' }],
        [{ type: 'fetchMergeRequests' }],
        done,
      ));
  });

  describe('toggleSortOrder', () => {
    it('should commit toggleSortOrder', done =>
      testAction(
        actions.toggleSortOrder,
        null,
        mockedContext.state,
        [{ type: types.TOGGLE_SORT_ORDER }],
        [{ type: 'fetchMergeRequests' }],
        done,
      ));
  });

  describe('setColumnMetric', () => {
    it('should commit setColumnMetric', done =>
      testAction(
        actions.setColumnMetric,
        'time_to_first_comment',
        mockedContext.state,
        [{ type: types.SET_COLUMN_METRIC, payload: 'time_to_first_comment' }],
        [],
        done,
      ));
  });

  describe('setPage', () => {
    it('should commit setPage', done =>
      testAction(
        actions.setPage,
        2,
        mockedContext.state,
        [{ type: types.SET_PAGE, payload: 2 }],
        [{ type: 'fetchMergeRequests' }],
        done,
      ));
  });
});
