import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import {
  urlParamsToObject,
  parseBoolean,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { IssuableStates } from '~/issuable_list/constants';

import EpicsListApp from './components/epics_list_root.vue';

Vue.use(VueApollo);

export default function initEpicsList({ mountPointSelector }) {
  const mountPointEl = document.querySelector(mountPointSelector);

  if (!mountPointEl) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    page = 1,
    prev = '',
    next = '',
    initialState = IssuableStates.Opened,
    initialSortBy = 'start_date_desc',
    canCreateEpic,
    canBulkEditEpics,
    epicsCountOpened,
    epicsCountClosed,
    epicsCountAll,
  } = mountPointEl.dataset;

  const initialFilterParams = Object.assign(
    convertObjectPropsToCamelCase(urlParamsToObject(window.location.search.substring(1)), {
      dropKeys: ['scope', 'utf8', 'state', 'sort'], // These keys are unsupported/unnecessary
    }),
  );

  return new Vue({
    el: mountPointEl,
    apolloProvider,
    provide: {
      ...mountPointEl.dataset,
      page: parseInt(page, 10),
      prev,
      next,
      canCreateEpic: parseBoolean(canCreateEpic),
      canBulkEditEpics: parseBoolean(canBulkEditEpics),
      initialState,
      initialSortBy,
      epicsCount: {
        [IssuableStates.Opened]: parseInt(epicsCountOpened, 10),
        [IssuableStates.Closed]: parseInt(epicsCountClosed, 10),
        [IssuableStates.All]: parseInt(epicsCountAll, 10),
      },
    },
    render: createElement =>
      createElement(EpicsListApp, {
        props: {
          initialFilterParams,
        },
      }),
  });
}
