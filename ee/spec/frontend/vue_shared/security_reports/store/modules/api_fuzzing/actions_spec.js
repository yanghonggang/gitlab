import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/actions';
import * as types from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/mutation_types';
import createState from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';

const diffEndpoint = 'diff-endpoint.json';
const blobPath = 'blob-path.json';
const reports = {
  base: 'base',
  head: 'head',
  enrichData: 'enrichData',
  diff: 'diff',
};
const error = 'Something went wrong';
const vulnerabilityFeedbackPath = 'vulnerability-feedback-path';
const rootState = { vulnerabilityFeedbackPath, blobPath };
const issue = {};
let state;

// See also the corresponding CE specs in
// spec/frontend/vue_shared/security_reports/store/modules/sast/actions_spec.js
describe('EE api fuzzing report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('updateVulnerability', () => {
    it(`should commit ${types.UPDATE_VULNERABILITY} with the correct response`, done => {
      testAction(
        actions.updateVulnerability,
        issue,
        state,
        [
          {
            type: types.UPDATE_VULNERABILITY,
            payload: issue,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('setDiffEndpoint', () => {
    it(`should commit ${types.SET_DIFF_ENDPOINT} with the correct path`, done => {
      testAction(
        actions.setDiffEndpoint,
        diffEndpoint,
        state,
        [
          {
            type: types.SET_DIFF_ENDPOINT,
            payload: diffEndpoint,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('requestDiff', () => {
    it(`should commit ${types.REQUEST_DIFF}`, done => {
      testAction(actions.requestDiff, {}, state, [{ type: types.REQUEST_DIFF }], [], done);
    });
  });

  describe('receiveDiffSuccess', () => {
    it(`should commit ${types.RECEIVE_DIFF_SUCCESS} with the correct response`, done => {
      testAction(
        actions.receiveDiffSuccess,
        reports,
        state,
        [
          {
            type: types.RECEIVE_DIFF_SUCCESS,
            payload: reports,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveDiffError', () => {
    it(`should commit ${types.RECEIVE_DIFF_ERROR} with the correct response`, done => {
      testAction(
        actions.receiveDiffError,
        error,
        state,
        [
          {
            type: types.RECEIVE_DIFF_ERROR,
            payload: error,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDiff', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.paths.diffEndpoint = diffEndpoint;
      rootState.canReadVulnerabilityFeedback = true;
    });

    afterEach(() => {
      mock.restore();
    });

    describe('when diff and vulnerability feedback endpoints respond successfully', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(200, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(200, reports.enrichData);
      });

      it('should dispatch the `receiveDiffSuccess` action', done => {
        const { diff, enrichData } = reports;
        testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestDiff' },
            {
              type: 'receiveDiffSuccess',
              payload: {
                diff,
                enrichData,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when diff endpoint responds successfully and fetching vulnerability feedback is not authorized', () => {
      beforeEach(() => {
        rootState.canReadVulnerabilityFeedback = false;
        mock.onGet(diffEndpoint).replyOnce(200, reports.diff);
      });

      it('should dispatch the `receiveDiffSuccess` action with empty enrich data', done => {
        const { diff } = reports;
        const enrichData = [];
        testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [
            { type: 'requestDiff' },
            {
              type: 'receiveDiffSuccess',
              payload: {
                diff,
                enrichData,
              },
            },
          ],
          done,
        );
      });
    });

    describe('when the vulnerability feedback endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(200, reports.diff)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(404);
      });

      it('should dispatch the `receiveError` action', done => {
        testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestDiff' }, { type: 'receiveDiffError' }],
          done,
        );
      });
    });

    describe('when the diff endpoint fails', () => {
      beforeEach(() => {
        mock
          .onGet(diffEndpoint)
          .replyOnce(404)
          .onGet(vulnerabilityFeedbackPath)
          .replyOnce(200, reports.enrichData);
      });

      it('should dispatch the `receiveDiffError` action', done => {
        testAction(
          actions.fetchDiff,
          {},
          { ...rootState, ...state },
          [],
          [{ type: 'requestDiff' }, { type: 'receiveDiffError' }],
          done,
        );
      });
    });
  });
});
