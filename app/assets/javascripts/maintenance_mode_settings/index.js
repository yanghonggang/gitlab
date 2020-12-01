import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import { createStore } from './store';
import MaintenanceModeSettingsApp from './components/app.vue';

Vue.use(Translate);

export const initMaintenanceModeSettings = () => {
  const el = document.getElementById('js-maintenance-mode-settings');

  return new Vue({
    el,
    store: createStore(),
    render(createElement) {
      return createElement(MaintenanceModeSettingsApp);
    },
  });
};
