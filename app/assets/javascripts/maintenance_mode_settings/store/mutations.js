import * as types from './mutation_types';
import { DEFAULT_MAINTENANCE_ENABLED, DEFAULT_BANNER_MESSAGE } from '../constants';

export default {
  [types.REQUEST_MAINTENANCE_MODE_SETTINGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_MAINTENANCE_MODE_SETTINGS_SUCCESS](state, { maintenanceEnabled, bannerMessage }) {
    state.isLoading = false;
    state.maintenanceEnabled = maintenanceEnabled;
    state.bannerMessage = bannerMessage;
  },
  [types.RECEIVE_MAINTENANCE_MODE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.maintenanceEnabled = DEFAULT_MAINTENANCE_ENABLED;
    state.bannerMessage = DEFAULT_BANNER_MESSAGE;
  },
  [types.REQUEST_UPDATE_MAINTENANCE_MODE_SETTINGS](state) {
    state.isLoading = true;
  },
  [types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_SUCCESS](
    state,
    { maintenanceEnabled, bannerMessage },
  ) {
    state.isLoading = false;
    state.maintenanceEnabled = maintenanceEnabled;
    state.bannerMessage = bannerMessage;
  },
  [types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_ERROR](state) {
    state.isLoading = false;
    state.maintenanceEnabled = DEFAULT_MAINTENANCE_ENABLED;
    state.bannerMessage = DEFAULT_BANNER_MESSAGE;
  },
  [types.SET_MAINTENANCE_ENABLED](state, maintenanceEnabled) {
    state.maintenanceEnabled = maintenanceEnabled;
  },
  [types.SET_BANNER_MESSAGE](state, bannerMessage) {
    state.bannerMessage = bannerMessage;
  },
};
