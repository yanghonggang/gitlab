import Vue from 'vue';

import Form from './components/form.vue';
import store from './stores';

export default () => {
  const el = document.querySelector('#js-compliance-framework-labels-form');

  const { fullPath, id = null } = el.dataset;

  return new Vue({
    el,
    store,
    components: {},
    render(createElement) {
      return createElement(Form, {
        props: {
          fullPath,
          id,
        },
      });
    },
  });
};
