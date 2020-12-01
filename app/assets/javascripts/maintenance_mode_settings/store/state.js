import { DEFAULT_MAINTENANCE_ENABLED, DEFAULT_BANNER_MESSAGE } from '../constants';

export const createState = () => ({
  isLoading: false,
  maintenanceEnabled: DEFAULT_MAINTENANCE_ENABLED,
  bannerMessage: DEFAULT_BANNER_MESSAGE,
});
