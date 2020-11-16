import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import * as actions from '~/search/store/actions';
import * as types from '~/search/store/mutation_types';
import * as urlUtils from '~/lib/utils/url_utility';
import createState from '~/search/store/state';
import axios from '~/lib/utils/axios_utils';
import createFlash from '~/flash';
import { MOCK_QUERY, MOCK_GROUPS, MOCK_PROJECT, MOCK_PROJECTS } from '../mock_data';

jest.mock('~/flash');

// We need some of the urlUtil methods to test the API.
// So instead of mocking the whole module I just target these two methods.
urlUtils.setUrlParams = jest.fn();
urlUtils.visitUrl = jest.fn();

describe('Global Search Store Actions', () => {
  let mock;
  let state;

  const noCallback = () => {};
  const flashCallback = () => {
    expect(createFlash).toHaveBeenCalledTimes(1);
    createFlash.mockClear();
  };

  beforeEach(() => {
    state = createState({ query: MOCK_QUERY });
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  describe.each`
    action                   | axiosMock                                             | type         | mutationCalls                                                                                           | callback
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 200, res: MOCK_GROUPS }}   | ${'success'} | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_SUCCESS, payload: MOCK_GROUPS }]}       | ${noCallback}
    ${actions.fetchGroups}   | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_GROUPS }, { type: types.RECEIVE_GROUPS_ERROR }]}                               | ${flashCallback}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 200, res: MOCK_PROJECTS }} | ${'success'} | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_SUCCESS, payload: MOCK_PROJECTS }]} | ${noCallback}
    ${actions.fetchProjects} | ${{ method: 'onGet', code: 500, res: null }}          | ${'error'}   | ${[{ type: types.REQUEST_PROJECTS }, { type: types.RECEIVE_PROJECTS_ERROR }]}                           | ${flashCallback}
  `(`axios calls`, ({ action, axiosMock, type, mutationCalls, callback }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct mutations`, () => {
          return testAction(action, null, state, mutationCalls, []).then(() => callback());
        });
      });
    });
  });

  describe('getProjectsData', () => {
    const mockCommit = () => {};
    beforeEach(() => {
      jest.spyOn(Api, 'groupProjects').mockResolvedValue(MOCK_PROJECTS);
      jest.spyOn(Api, 'projects').mockResolvedValue(MOCK_PROJECT);
    });

    describe('when groupId is set', () => {
      it('calls Api.groupProjects', () => {
        actions.fetchProjects({ commit: mockCommit, state });

        expect(Api.groupProjects).toHaveBeenCalled();
        expect(Api.projects).not.toHaveBeenCalled();
      });
    });

    describe('when groupId is not set', () => {
      beforeEach(() => {
        state = createState({ query: { group_id: null } });
      });

      it('calls Api.projects', () => {
        actions.fetchProjects({ commit: mockCommit, state });

        expect(Api.groupProjects).not.toHaveBeenCalled();
        expect(Api.projects).toHaveBeenCalled();
      });
    });
  });

  describe('setQuery', () => {
    const payload = { key: 'key1', value: 'value1' };

    it('calls the SET_QUERY mutation', done => {
      return testAction(
        actions.setQuery,
        payload,
        state,
        [{ type: types.SET_QUERY, payload }],
        [],
        done,
      );
    });
  });

  describe('applyQuery', () => {
    it('calls visitUrl and setParams with the state.query', () => {
      return testAction(actions.applyQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({ ...state.query, page: null });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('resetQuery', () => {
    it('calls visitUrl and setParams with empty values', () => {
      return testAction(actions.resetQuery, null, state, [], [], () => {
        expect(urlUtils.setUrlParams).toHaveBeenCalledWith({
          ...state.query,
          page: null,
          state: null,
          confidential: null,
        });
        expect(urlUtils.visitUrl).toHaveBeenCalled();
      });
    });
  });
});
