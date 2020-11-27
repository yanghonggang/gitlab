import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/analytics/code_review_analytics/store/modules/merge_requests/actions';
import * as types from 'ee/analytics/code_review_analytics/store/modules/merge_requests/mutation_types';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/merge_requests/state';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { mockMergeRequests } from '../../../mock_data';

jest.mock('~/flash');

describe('Code review analytics mergeRequests actions', () => {
  let state;
  let mock;

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
    state = {
      filters: {
        milestones: { selected: null },
        labels: { selected: [] },
      },
      ...getInitialState(),
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    createFlash.mockClear();
  });

  describe('setProjectId', () => {
    it('commits the SET_PROJECT_ID mutation', () =>
      testAction(
        actions.setProjectId,
        1,
        state,
        [
          {
            type: types.SET_PROJECT_ID,
            payload: 1,
          },
        ],
        [],
      ));
  });

  describe('fetchMergeRequests', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/analytics\/code_review/).replyOnce(200, mockMergeRequests, headers);
      });

      it('dispatches success with received data', () => {
        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [
            { type: types.REQUEST_MERGE_REQUESTS },
            {
              type: types.RECEIVE_MERGE_REQUESTS_SUCCESS,
              payload: { pageInfo, mergeRequests: mockMergeRequests },
            },
          ],
          [],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(/api\/(.*)\/analytics\/code_review/).replyOnce(500);
      });

      it('dispatches error', done => {
        testAction(
          actions.fetchMergeRequests,
          null,
          state,
          [
            { type: types.REQUEST_MERGE_REQUESTS },
            {
              type: types.RECEIVE_MERGE_REQUESTS_ERROR,
              payload: 500,
            },
          ],
          [],
          () => {
            expect(createFlash).toHaveBeenCalled();
            done();
          },
        );
      });
    });
  });

  describe('setPage', () => {
    it('commits SET_PAGE mutation', () => {
      testAction(actions.setPage, 2, state, [{ type: types.SET_PAGE, payload: 2 }], []);
    });
  });
});
