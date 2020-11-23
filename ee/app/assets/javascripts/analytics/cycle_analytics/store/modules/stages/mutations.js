import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

export default {
  [types.SET_SELECTED_STAGE](state, rawData) {
    state.selectedStage = convertObjectPropsToCamelCase(rawData);
  },
  [types.REQUEST_STAGE_MEDIANS](state) {
    state.medians = {};
  },
  [types.RECEIVE_STAGE_MEDIANS_SUCCESS](state, medians = []) {
    state.medians = medians.reduce(
      (acc, { id, value, error = null }) => ({
        ...acc,
        [id]: { value, error },
      }),
      {},
    );
  },
  [types.RECEIVE_STAGE_MEDIANS_ERROR](state) {
    state.medians = {};
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
    state.selectedStageError = '';
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.currentStageEvents = events.map(fields =>
      convertObjectPropsToCamelCase(fields, { deep: true }),
    );
    state.isEmptyStage = !events.length;
    state.isLoadingStage = false;
    state.selectedStageError = '';
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state, message) {
    state.isEmptyStage = true;
    state.isLoadingStage = false;
    state.selectedStageError = message;
  },
  [types.REQUEST_REORDER_STAGE](state) {
    state.isSavingStageOrder = true;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_SUCCESS](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = false;
  },
  [types.RECEIVE_REORDER_STAGE_ERROR](state) {
    state.isSavingStageOrder = false;
    state.errorSavingStageOrder = true;
  },
  [types.REQUEST_UPDATE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_UPDATE_STAGE_SUCCESS](state) {
    state.isLoading = false;
  },
  [types.RECEIVE_UPDATE_STAGE_ERROR](state) {
    state.isLoading = false;
  },
  [types.REQUEST_REMOVE_STAGE](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_REMOVE_STAGE_RESPONSE](state) {
    state.isLoading = false;
  },
};
