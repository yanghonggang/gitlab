import Vue from 'vue';
import Vuex from 'vuex';
import pipelineJobs from 'ee/security_dashboard/store/modules/pipeline_jobs';
import configureMediator from './mediator';
import * as actions from './actions';
import * as getters from './getters';
import mutations from './mutations';
import state from './state';
import { MODULE_SAST, MODULE_SECRET_DETECTION } from './constants';

import sast from './modules/sast';
import secretDetection from './modules/secret_detection';

Vue.use(Vuex);

export default () =>
  new Vuex.Store({
    modules: {
      [MODULE_SAST]: sast,
      [MODULE_SECRET_DETECTION]: secretDetection,
      pipelineJobs,
    },
    actions,
    getters,
    mutations,
    state: state(),
    plugins: [configureMediator],
  });
