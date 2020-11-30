import Vue from 'vue';

import List from './components/list.vue';
import store from './stores';

export default () => {
  const el = document.querySelector('#js-compliance-framework-labels-list');

  const { fullPath } = el.dataset;

  return new Vue({
    el,
    store,
    components: {},
    render(createElement) {
      return createElement(List, {
        props: {
          fullPath,
        },
      });
    },
  });
};
