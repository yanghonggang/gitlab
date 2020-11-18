import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/geo_node_form/store/actions';
import * as types from 'ee/geo_node_form/store/mutation_types';
import createState from 'ee/geo_node_form/store/state';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as flash } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { MOCK_SYNC_NAMESPACES, MOCK_NODE, MOCK_ERROR_MESSAGE } from '../mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.fn(),
}));

describe('GeoNodeForm Store Actions', () => {
  let state;
  let mock;

  const noCallback = () => {};
  const flashCallback = () => {
    expect(flash).toHaveBeenCalledTimes(1);
    flash.mockClear();
  };
  const visitUrlCallback = () => {
    expect(visitUrl).toHaveBeenCalledWith('/admin/geo/nodes');
  };

  beforeEach(() => {
    state = createState();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe.each`
    action                                  | data                               | mutationName                             | mutationCall                                                                      | callback
    ${actions.requestSyncNamespaces}        | ${null}                            | ${types.REQUEST_SYNC_NAMESPACES}         | ${{ type: types.REQUEST_SYNC_NAMESPACES }}                                        | ${noCallback}
    ${actions.receiveSyncNamespacesSuccess} | ${MOCK_SYNC_NAMESPACES}            | ${types.RECEIVE_SYNC_NAMESPACES_SUCCESS} | ${{ type: types.RECEIVE_SYNC_NAMESPACES_SUCCESS, payload: MOCK_SYNC_NAMESPACES }} | ${noCallback}
    ${actions.receiveSyncNamespacesError}   | ${null}                            | ${types.RECEIVE_SYNC_NAMESPACES_ERROR}   | ${{ type: types.RECEIVE_SYNC_NAMESPACES_ERROR }}                                  | ${flashCallback}
    ${actions.requestSaveGeoNode}           | ${null}                            | ${types.REQUEST_SAVE_GEO_NODE}           | ${{ type: types.REQUEST_SAVE_GEO_NODE }}                                          | ${noCallback}
    ${actions.receiveSaveGeoNodeSuccess}    | ${null}                            | ${types.RECEIVE_SAVE_GEO_NODE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }}                                 | ${visitUrlCallback}
    ${actions.receiveSaveGeoNodeError}      | ${{ message: MOCK_ERROR_MESSAGE }} | ${types.RECEIVE_SAVE_GEO_NODE_COMPLETE}  | ${{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }}                                 | ${flashCallback}
    ${actions.setError}                     | ${{ key: 'name', error: 'error' }} | ${types.SET_ERROR}                       | ${{ type: types.SET_ERROR, payload: { key: 'name', error: 'error' } }}            | ${noCallback}
  `(`non-axios calls`, ({ action, data, mutationName, mutationCall, callback }) => {
    describe(action.name, () => {
      it(`should commit mutation ${mutationName}`, () => {
        return testAction(action, data, state, [mutationCall], []).then(() => callback());
      });
    });
  });

  describe.each`
    action                         | axiosMock                                                                | data                          | type         | actionCalls
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: 200, res: MOCK_SYNC_NAMESPACES }}             | ${null}                       | ${'success'} | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesSuccess', payload: MOCK_SYNC_NAMESPACES }]}
    ${actions.fetchSyncNamespaces} | ${{ method: 'onGet', code: 500, res: null }}                             | ${null}                       | ${'error'}   | ${[{ type: 'requestSyncNamespaces' }, { type: 'receiveSyncNamespacesError' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPost', code: 200, res: { ...MOCK_NODE, id: null } }}      | ${{ ...MOCK_NODE, id: null }} | ${'success'} | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeSuccess' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPost', code: 500, res: { message: MOCK_ERROR_MESSAGE } }} | ${{ ...MOCK_NODE, id: null }} | ${'error'}   | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeError', payload: { message: MOCK_ERROR_MESSAGE } }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPut', code: 200, res: MOCK_NODE }}                        | ${MOCK_NODE}                  | ${'success'} | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeSuccess' }]}
    ${actions.saveGeoNode}         | ${{ method: 'onPut', code: 500, res: { message: MOCK_ERROR_MESSAGE } }}  | ${MOCK_NODE}                  | ${'error'}   | ${[{ type: 'requestSaveGeoNode' }, { type: 'receiveSaveGeoNodeError', payload: { message: MOCK_ERROR_MESSAGE } }]}
  `(`axios calls`, ({ action, axiosMock, data, type, actionCalls }) => {
    describe(action.name, () => {
      describe(`on ${type}`, () => {
        beforeEach(() => {
          mock[axiosMock.method]().replyOnce(axiosMock.code, axiosMock.res);
        });
        it(`should dispatch the correct request and actions`, () => {
          return testAction(action, data, state, [], actionCalls);
        });
      });
    });
  });

  describe('receiveSaveGeoNodeError', () => {
    const defaultErrorMessage = 'There was an error saving this Geo Node.';

    it('when message passed it builds the error message correctly', () => {
      return testAction(
        actions.receiveSaveGeoNodeError,
        { message: MOCK_ERROR_MESSAGE },
        state,
        [{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }],
        [],
      ).then(() => {
        const errors = "Errors: name can't be blank, url can't be blank, url must be a valid URL";
        expect(flash).toHaveBeenCalledWith(`${defaultErrorMessage} ${errors}`);
        flash.mockClear();
      });
    });

    it('when no data is passed it defaults the error message', () => {
      return testAction(
        actions.receiveSaveGeoNodeError,
        null,
        state,
        [{ type: types.RECEIVE_SAVE_GEO_NODE_COMPLETE }],
        [],
      ).then(() => {
        expect(flash).toHaveBeenCalledWith(defaultErrorMessage);
        flash.mockClear();
      });
    });
  });
});
