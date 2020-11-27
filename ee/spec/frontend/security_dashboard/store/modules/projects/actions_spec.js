import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_dashboard/store/modules/projects/actions';
import * as types from 'ee/security_dashboard/store/modules/projects/mutation_types';
import createState from 'ee/security_dashboard/store/modules/projects/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import axios from '~/lib/utils/axios_utils';

import mockData from './data/mock_data.json';

describe('projects actions', () => {
  const data = mockData;
  const endpoint = `${TEST_HOST}/projects.json`;

  describe('fetchProjects', () => {
    let mock;
    const state = createState();

    beforeEach(() => {
      state.projectsEndpoint = endpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      const expectedParams = {
        include_subgroups: true,
        with_security_reports: true,
        with_shared: false,
      };

      beforeEach(() => {
        mock.onGet(state.projectsEndpoint).replyOnce(config => {
          const hasExpectedParams = Object.keys(expectedParams).every(
            param => config.params[param] === expectedParams[param],
          );

          return hasExpectedParams ? [200, data] : [400];
        });
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [
            { type: 'requestProjects' },
            {
              type: 'receiveProjectsSuccess',
              payload: { projects: data },
            },
          ],
          done,
        );
      });
    });

    describe('calls the API multiple times if there is a next page', () => {
      beforeEach(() => {
        mock
          .onGet(state.projectsEndpoint, { page: '1' })
          .replyOnce(200, [1], { 'x-next-page': '2' });

        mock.onGet(state.projectsEndpoint, { page: '2' }).replyOnce(200, [2]);
      });

      it('should dispatch the request and success actions', done => {
        testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [
            { type: 'requestProjects' },
            {
              type: 'receiveProjectsSuccess',
              payload: { projects: [1, 2] },
            },
          ],
          done,
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.projectsEndpoint).replyOnce(404, {});
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
          done,
        );
      });
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.projectsEndpoint = '';
      });

      it('should not do anything', done => {
        testAction(actions.fetchProjects, {}, state, [], [], done);
      });
    });
  });

  describe('receiveProjectsSuccess', () => {
    it('should commit the success mutation', done => {
      const state = createState();

      testAction(
        actions.receiveProjectsSuccess,
        { projects: data },
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_SUCCESS,
            payload: { projects: data },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('should commit the error mutation', done => {
      const state = createState();

      testAction(
        actions.receiveProjectsError,
        {},
        state,
        [{ type: types.RECEIVE_PROJECTS_ERROR }],
        [],
        done,
      );
    });
  });

  describe('requestProjects', () => {
    it('should commit the request mutation', done => {
      const state = createState();

      testAction(actions.requestProjects, {}, state, [{ type: types.REQUEST_PROJECTS }], [], done);
    });
  });

  describe('setProjectsEndpoint', () => {
    it('should commit the correct mutuation', done => {
      const state = createState();

      testAction(
        actions.setProjectsEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_PROJECTS_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
        done,
      );
    });
  });
});
