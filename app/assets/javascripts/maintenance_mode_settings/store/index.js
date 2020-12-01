import Vue from 'vue';
import Vuex from 'vuex';
import * as actions from './actions';
import mutations from './mutations';
import { createState } from './state';

Vue.use(Vuex);

export const getStoreConfig = () => ({
  actions,
  mutations,
  state: createState(),
});

export const createStore = config => new Vuex.Store(getStoreConfig(config));
