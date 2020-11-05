import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CiLint from './components/ci_lint.vue';
import resolvers from './graphql/resolvers';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(resolvers),
});

export default (containerId = '#js-ci-lint') => {
  const containerEl = document.querySelector(containerId);
  const { endpoint, helpPagePath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    render(createElement) {
      return createElement(CiLint, {
        props: {
          endpoint,
          helpPagePath,
        },
      });
    },
  });
};
