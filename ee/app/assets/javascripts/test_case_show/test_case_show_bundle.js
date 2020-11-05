import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

import TestCaseShowApp from './components/test_case_show_root.vue';

Vue.use(VueApollo);

export default function initTestCaseShow({ mountPointSelector }) {
  const el = document.querySelector(mountPointSelector);

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      ...el.dataset,
      canEditTestCase: parseBoolean(el.dataset.canEditTestCase),
    },
    render: createElement => createElement(TestCaseShowApp),
  });
}
