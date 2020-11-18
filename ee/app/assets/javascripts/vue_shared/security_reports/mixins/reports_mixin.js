import { LOADING, ERROR, SUCCESS } from '~/reports/constants';

export default {
  methods: {
    checkReportStatus(loading, error) {
      if (loading) {
        return LOADING;
      }
      if (error) {
        return ERROR;
      }

      return SUCCESS;
    },
  },
};
