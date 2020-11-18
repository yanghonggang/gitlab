import { TABLE_TYPE_DEFAULT, TABLE_TYPE_FREE, TABLE_TYPE_TRIAL } from 'ee/billings/constants';
import * as types from 'ee/billings/stores/modules/subscription/mutation_types';
import mutations from 'ee/billings/stores/modules/subscription/mutations';
import createState from 'ee/billings/stores/modules/subscription/state';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { mockDataSubscription } from '../../../mock_data';

describe('EE billings subscription module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.SET_NAMESPACE_ID, () => {
    it('sets namespaceId', () => {
      const expectedNamespaceId = 'test';

      expect(state.namespaceId).toBeNull();

      mutations[types.SET_NAMESPACE_ID](state, expectedNamespaceId);

      expect(state.namespaceId).toEqual(expectedNamespaceId);
    });
  });

  describe(types.REQUEST_SUBSCRIPTION, () => {
    beforeEach(() => {
      mutations[types.REQUEST_SUBSCRIPTION](state);
    });

    it('sets isLoadingSubscription to true', () => {
      expect(state.isLoadingSubscription).toBeTruthy();
    });

    it('sets hasErrorSubscription to false', () => {
      expect(state.hasErrorSubscription).toBeFalsy();
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_SUCCESS, () => {
    const getColumnValues = columns =>
      columns.reduce(
        (acc, { id, value }) => ({
          ...acc,
          [id]: value,
        }),
        {},
      );
    const getStateTableValues = key =>
      state.tables[key].rows.map(({ columns }) => getColumnValues(columns));

    describe.each`
      desc                        | subscription                  | tableKey
      ${'with Gold subscription'} | ${mockDataSubscription.gold}  | ${TABLE_TYPE_DEFAULT}
      ${'with Free plan'}         | ${mockDataSubscription.free}  | ${TABLE_TYPE_FREE}
      ${'with Gold trial'}        | ${mockDataSubscription.trial} | ${TABLE_TYPE_TRIAL}
    `('$desc', ({ subscription, tableKey }) => {
      beforeEach(() => {
        state.isLoadingSubscription = true;
        mutations[types.RECEIVE_SUBSCRIPTION_SUCCESS](state, subscription);
      });

      it('sets isLoadingSubscription to false', () => {
        expect(state.isLoadingSubscription).toBeFalsy();
      });

      it('sets plan', () => {
        const { plan } = convertObjectPropsToCamelCase(subscription, { deep: true });

        expect(state.plan).toEqual(plan);
      });

      it(`it updates table ${tableKey} with subscription plan`, () => {
        expect(getStateTableValues(tableKey)).toMatchSnapshot();
      });
    });
  });

  describe(types.RECEIVE_SUBSCRIPTION_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_SUBSCRIPTION_ERROR](state);
    });

    it('sets isLoadingSubscription to false', () => {
      expect(state.isLoadingSubscription).toBeFalsy();
    });

    it('sets hasErrorSubscription to true', () => {
      expect(state.hasErrorSubscription).toBeTruthy();
    });
  });
});
