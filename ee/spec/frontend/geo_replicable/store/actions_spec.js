import Api from 'ee/api';
import { ACTION_TYPES, PREV, NEXT, DEFAULT_PAGE_SIZE } from 'ee/geo_replicable/constants';
import buildReplicableTypeQuery from 'ee/geo_replicable/graphql/replicable_type_query_builder';
import * as actions from 'ee/geo_replicable/store/actions';
import * as types from 'ee/geo_replicable/store/mutation_types';
import createState from 'ee/geo_replicable/store/state';
import { gqClient } from 'ee/geo_replicable/utils';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as flash } from '~/flash';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import toast from '~/vue_shared/plugins/global_toast';
import {
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_BASIC_FETCH_RESPONSE,
  MOCK_BASIC_POST_RESPONSE,
  MOCK_REPLICABLE_TYPE,
  MOCK_RESTFUL_PAGINATION_DATA,
  MOCK_BASIC_GRAPHQL_QUERY_RESPONSE,
  MOCK_GRAPHQL_PAGINATION_DATA,
  MOCK_GRAPHQL_REGISTRY,
} from '../mock_data';

jest.mock('~/flash');
jest.mock('~/vue_shared/plugins/global_toast');

describe('GeoReplicable Store Actions', () => {
  let state;

  beforeEach(() => {
    state = createState({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null });
  });

  describe('requestReplicableItems', () => {
    it('should commit mutation REQUEST_REPLICABLE_ITEMS', done => {
      testAction(
        actions.requestReplicableItems,
        null,
        state,
        [{ type: types.REQUEST_REPLICABLE_ITEMS }],
        [],
        done,
      );
    });
  });

  describe('receiveReplicableItemsSuccess', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_SUCCESS', done => {
      testAction(
        actions.receiveReplicableItemsSuccess,
        { data: MOCK_BASIC_FETCH_DATA_MAP, pagination: MOCK_RESTFUL_PAGINATION_DATA },
        state,
        [
          {
            type: types.RECEIVE_REPLICABLE_ITEMS_SUCCESS,
            payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination: MOCK_RESTFUL_PAGINATION_DATA },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('receiveReplicableItemsError', () => {
    it('should commit mutation RECEIVE_REPLICABLE_ITEMS_ERROR', () => {
      testAction(
        actions.receiveReplicableItemsError,
        null,
        state,
        [{ type: types.RECEIVE_REPLICABLE_ITEMS_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('fetchReplicableItems', () => {
    describe('with graphql', () => {
      beforeEach(() => {
        state.useGraphQl = true;
      });

      it('calls fetchReplicableItemsGraphQl', done => {
        testAction(
          actions.fetchReplicableItems,
          null,
          state,
          [],
          [
            { type: 'requestReplicableItems' },
            { type: 'fetchReplicableItemsGraphQl', payload: null },
          ],
          done,
        );
      });
    });

    describe('without graphql', () => {
      beforeEach(() => {
        state.useGraphQl = false;
      });

      it('calls fetchReplicableItemsRestful', done => {
        testAction(
          actions.fetchReplicableItems,
          null,
          state,
          [],
          [{ type: 'requestReplicableItems' }, { type: 'fetchReplicableItemsRestful' }],
          done,
        );
      });
    });
  });

  describe('fetchReplicableItemsGraphQl', () => {
    beforeEach(() => {
      state.graphqlFieldName = MOCK_GRAPHQL_REGISTRY;
    });

    describe('on success with no registry data', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockResolvedValue({
          data: {},
        });
      });

      const direction = null;
      const data = [];

      it('should not error and pass empty values to the mutations', () => {
        testAction(
          actions.fetchReplicableItemsGraphQl,
          direction,
          state,
          [],
          [
            {
              type: 'receiveReplicableItemsSuccess',
              payload: { data, pagination: null },
            },
          ],
          () => {
            expect(gqClient.query).toHaveBeenCalledWith({
              query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY),
              variables: { before: '', after: '', first: DEFAULT_PAGE_SIZE, last: null },
            });
          },
        );
      });
    });

    describe('on success', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockResolvedValue({
          data: MOCK_BASIC_GRAPHQL_QUERY_RESPONSE,
        });
        state.paginationData = MOCK_GRAPHQL_PAGINATION_DATA;
        state.paginationData.page = 1;
      });

      describe('with no direction set', () => {
        const direction = null;
        const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
        const data = registries.nodes;

        it('should call gqClient with no before/after variables as well as a first variable but no last variable', () => {
          testAction(
            actions.fetchReplicableItemsGraphQl,
            direction,
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data, pagination: registries.pageInfo },
              },
            ],
            () => {
              expect(gqClient.query).toHaveBeenCalledWith({
                query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY),
                variables: { before: '', after: '', first: DEFAULT_PAGE_SIZE, last: null },
              });
            },
          );
        });
      });

      describe('with direction set to "next"', () => {
        const direction = NEXT;
        const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
        const data = registries.nodes;

        it('should call gqClient with after variable but no before variable as well as a first variable but no last variable', () => {
          testAction(
            actions.fetchReplicableItemsGraphQl,
            direction,
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data, pagination: registries.pageInfo },
              },
            ],
            () => {
              expect(gqClient.query).toHaveBeenCalledWith({
                query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY),
                variables: {
                  before: '',
                  after: MOCK_GRAPHQL_PAGINATION_DATA.endCursor,
                  first: DEFAULT_PAGE_SIZE,
                  last: null,
                },
              });
            },
          );
        });
      });

      describe('with direction set to "prev"', () => {
        const direction = PREV;
        const registries = MOCK_BASIC_GRAPHQL_QUERY_RESPONSE.geoNode[MOCK_GRAPHQL_REGISTRY];
        const data = registries.nodes;

        it('should call gqClient with before variable but no after variable as well as a last variable but no first variable', () => {
          testAction(
            actions.fetchReplicableItemsGraphQl,
            direction,
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data, pagination: registries.pageInfo },
              },
            ],
            () => {
              expect(gqClient.query).toHaveBeenCalledWith({
                query: buildReplicableTypeQuery(MOCK_GRAPHQL_REGISTRY),
                variables: {
                  before: MOCK_GRAPHQL_PAGINATION_DATA.startCursor,
                  after: '',
                  first: null,
                  last: DEFAULT_PAGE_SIZE,
                },
              });
            },
          );
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockRejectedValue();
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchReplicableItemsGraphQl,
          null,
          state,
          [],
          [{ type: 'receiveReplicableItemsError' }],
          done,
        );
      });
    });
  });

  describe('fetchReplicableItemsRestful', () => {
    const normalizedHeaders = normalizeHeaders(MOCK_BASIC_FETCH_RESPONSE.headers);
    const pagination = parseIntPagination(normalizedHeaders);

    describe('on success', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getGeoReplicableItems').mockResolvedValue(MOCK_BASIC_FETCH_RESPONSE);
      });

      describe('with no params set', () => {
        const defaultParams = {
          page: 1,
          search: null,
          sync_status: null,
        };

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItemsRestful,
            {},
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination },
              },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(
                MOCK_REPLICABLE_TYPE,
                defaultParams,
              );
            },
          );
        });
      });

      describe('with params set', () => {
        beforeEach(() => {
          state.paginationData.page = 3;
          state.searchFilter = 'test search';
          state.currentFilterIndex = 2;
        });

        it('should call getGeoReplicableItems with default queryParams', () => {
          testAction(
            actions.fetchReplicableItemsRestful,
            {},
            state,
            [],
            [
              {
                type: 'receiveReplicableItemsSuccess',
                payload: { data: MOCK_BASIC_FETCH_DATA_MAP, pagination },
              },
            ],
            () => {
              expect(Api.getGeoReplicableItems).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
                page: 3,
                search: 'test search',
                sync_status: state.filterOptions[2].value,
              });
            },
          );
        });
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        jest.spyOn(Api, 'getGeoReplicableItems').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.fetchReplicableItemsRestful,
          {},
          state,
          [],
          [{ type: 'receiveReplicableItemsError' }],
          done,
        );
      });
    });
  });

  describe('requestInitiateAllReplicableSyncs', () => {
    it('should commit mutation REQUEST_INITIATE_ALL_REPLICABLE_SYNCS', done => {
      testAction(
        actions.requestInitiateAllReplicableSyncs,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_ALL_REPLICABLE_SYNCS }],
        [],
        done,
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS and call fetchReplicableItems and toast', () => {
      testAction(
        actions.receiveInitiateAllReplicableSyncsSuccess,
        { action: ACTION_TYPES.RESYNC },
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateAllReplicableSyncsError', () => {
    it('should commit mutation RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR', () => {
      testAction(
        actions.receiveInitiateAllReplicableSyncsError,
        ACTION_TYPES.RESYNC,
        state,
        [{ type: types.RECEIVE_INITIATE_ALL_REPLICABLE_SYNCS_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('initiateAllReplicableSyncs', () => {
    let action;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest
          .spyOn(Api, 'initiateAllGeoReplicableSyncs')
          .mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateAllReplicableSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsSuccess', payload: { action } },
          ],
          () => {
            expect(Api.initiateAllGeoReplicableSyncs).toHaveBeenCalledWith(
              MOCK_REPLICABLE_TYPE,
              action,
            );
          },
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        jest.spyOn(Api, 'initiateAllGeoReplicableSyncs').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateAllReplicableSyncs,
          action,
          state,
          [],
          [
            { type: 'requestInitiateAllReplicableSyncs' },
            { type: 'receiveInitiateAllReplicableSyncsError' },
          ],
          done,
        );
      });
    });
  });

  describe('requestInitiateReplicableSync', () => {
    it('should commit mutation REQUEST_INITIATE_REPLICABLE_SYNC', done => {
      testAction(
        actions.requestInitiateReplicableSync,
        null,
        state,
        [{ type: types.REQUEST_INITIATE_REPLICABLE_SYNC }],
        [],
        done,
      );
    });
  });

  describe('receiveInitiateReplicableSyncSuccess', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS and call fetchReplicableItems and toast', () => {
      testAction(
        actions.receiveInitiateReplicableSyncSuccess,
        { action: ACTION_TYPES.RESYNC, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_SUCCESS }],
        [{ type: 'fetchReplicableItems' }],
        () => {
          expect(toast).toHaveBeenCalledTimes(1);
          toast.mockClear();
        },
      );
    });
  });

  describe('receiveInitiateReplicableSyncError', () => {
    it('should commit mutation RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR', () => {
      testAction(
        actions.receiveInitiateReplicableSyncError,
        { action: ACTION_TYPES.RESYNC, projectId: 1, projectName: 'test' },
        state,
        [{ type: types.RECEIVE_INITIATE_REPLICABLE_SYNC_ERROR }],
        [],
        () => {
          expect(flash).toHaveBeenCalledTimes(1);
        },
      );
    });
  });

  describe('initiateReplicableSync', () => {
    let action;
    let projectId;
    let name;

    describe('on success', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest.spyOn(Api, 'initiateGeoReplicableSync').mockResolvedValue(MOCK_BASIC_POST_RESPONSE);
      });

      it('should dispatch the request with correct replicable param and success actions', () => {
        testAction(
          actions.initiateReplicableSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            { type: 'receiveInitiateReplicableSyncSuccess', payload: { name, action } },
          ],
          () => {
            expect(Api.initiateGeoReplicableSync).toHaveBeenCalledWith(MOCK_REPLICABLE_TYPE, {
              projectId,
              action,
            });
          },
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        action = ACTION_TYPES.RESYNC;
        projectId = 1;
        name = 'test';
        jest.spyOn(Api, 'initiateGeoReplicableSync').mockRejectedValue(new Error(500));
      });

      it('should dispatch the request and error actions', done => {
        testAction(
          actions.initiateReplicableSync,
          { projectId, name, action },
          state,
          [],
          [
            { type: 'requestInitiateReplicableSync' },
            {
              type: 'receiveInitiateReplicableSyncError',
              payload: { name: 'test' },
            },
          ],
          done,
        );
      });
    });
  });

  describe('setFilter', () => {
    it('should commit mutation SET_FILTER', done => {
      const testValue = 1;

      testAction(
        actions.setFilter,
        testValue,
        state,
        [{ type: types.SET_FILTER, payload: testValue }],
        [],
        done,
      );
    });
  });

  describe('setSearch', () => {
    it('should commit mutation SET_SEARCH', done => {
      const testValue = 'Test Search';

      testAction(
        actions.setSearch,
        testValue,
        state,
        [{ type: types.SET_SEARCH, payload: testValue }],
        [],
        done,
      );
    });
  });

  describe('setPage', () => {
    it('should commit mutation SET_PAGE', done => {
      state.paginationData.page = 1;

      const testValue = 2;

      testAction(
        actions.setPage,
        testValue,
        state,
        [{ type: types.SET_PAGE, payload: testValue }],
        [],
        done,
      );
    });
  });
});
