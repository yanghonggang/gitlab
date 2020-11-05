import Api from '~/api';
import * as types from './mutation_types';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export const setNamespaceId = ({ commit }, namespaceId) => {
  commit(types.SET_NAMESPACE_ID, namespaceId);
};

export const fetchBillableMembersList = ({ dispatch, state }, page) => {
  dispatch('requestBillableMembersList');

  return Api.fetchBillableGroupMembersList(state.namespaceId, { page })
    .then(data => dispatch('receiveBillableMembersListSuccess', data))
    .catch(() => dispatch('receiveBillableMembersListError'));
};

export const requestBillableMembersList = ({ commit }) => commit(types.REQUEST_BILLABLE_MEMBERS);

export const receiveBillableMembersListSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_BILLABLE_MEMBERS_SUCCESS, response);

export const receiveBillableMembersListError = ({ commit }) => {
  createFlash({
    message: s__('Billing|An error occurred while loading billable members list'),
  });
  commit(types.RECEIVE_BILLABLE_MEMBERS_ERROR);
};
