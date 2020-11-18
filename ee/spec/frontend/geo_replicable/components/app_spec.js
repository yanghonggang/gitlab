import { GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import GeoReplicableApp from 'ee/geo_replicable/components/app.vue';
import GeoReplicable from 'ee/geo_replicable/components/geo_replicable.vue';
import GeoReplicableEmptyState from 'ee/geo_replicable/components/geo_replicable_empty_state.vue';
import GeoReplicableFilterBar from 'ee/geo_replicable/components/geo_replicable_filter_bar.vue';
import initStore from 'ee/geo_replicable/store';
import {
  MOCK_GEO_REPLICATION_SVG_PATH,
  MOCK_GEO_TROUBLESHOOTING_LINK,
  MOCK_BASIC_FETCH_DATA_MAP,
  MOCK_REPLICABLE_TYPE,
  MOCK_GRAPHQL_REGISTRY,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('GeoReplicableApp', () => {
  let wrapper;
  let store;

  const propsData = {
    geoTroubleshootingLink: MOCK_GEO_TROUBLESHOOTING_LINK,
    geoReplicableEmptySvgPath: MOCK_GEO_REPLICATION_SVG_PATH,
  };

  const createStore = options => {
    store = initStore({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null, ...options });
    jest.spyOn(store, 'dispatch').mockImplementation();
  };

  const createComponent = () => {
    wrapper = shallowMount(GeoReplicableApp, {
      localVue,
      store,
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGeoReplicableContainer = () => wrapper.find('.geo-replicable-container');
  const findGlLoadingIcon = () => findGeoReplicableContainer().find(GlLoadingIcon);
  const findGeoReplicable = () => findGeoReplicableContainer().find(GeoReplicable);
  const findGeoReplicableEmptyState = () =>
    findGeoReplicableContainer().find(GeoReplicableEmptyState);
  const findGeoReplicableFilterBar = () =>
    findGeoReplicableContainer().find(GeoReplicableFilterBar);

  describe.each`
    isLoading | graphqlFieldName         | replicableItems              | showReplicableItems | showEmptyState | showFilterBar | showLoader
    ${false}  | ${null}                  | ${MOCK_BASIC_FETCH_DATA_MAP} | ${true}             | ${false}       | ${true}       | ${false}
    ${false}  | ${null}                  | ${[]}                        | ${false}            | ${true}        | ${true}       | ${false}
    ${false}  | ${MOCK_GRAPHQL_REGISTRY} | ${MOCK_BASIC_FETCH_DATA_MAP} | ${true}             | ${false}       | ${false}      | ${false}
    ${false}  | ${MOCK_GRAPHQL_REGISTRY} | ${[]}                        | ${false}            | ${true}        | ${false}      | ${false}
    ${true}   | ${null}                  | ${MOCK_BASIC_FETCH_DATA_MAP} | ${false}            | ${false}       | ${true}       | ${true}
    ${true}   | ${null}                  | ${[]}                        | ${false}            | ${false}       | ${true}       | ${true}
    ${true}   | ${MOCK_GRAPHQL_REGISTRY} | ${MOCK_BASIC_FETCH_DATA_MAP} | ${false}            | ${false}       | ${false}      | ${true}
    ${true}   | ${MOCK_GRAPHQL_REGISTRY} | ${[]}                        | ${false}            | ${false}       | ${false}      | ${true}
  `(
    `template`,
    ({
      isLoading,
      graphqlFieldName,
      replicableItems,
      showReplicableItems,
      showEmptyState,
      showFilterBar,
      showLoader,
    }) => {
      beforeEach(() => {
        createStore({ graphqlFieldName });
        createComponent();
      });

      describe(`when isLoading is ${isLoading} and graphqlFieldName is ${graphqlFieldName}, ${
        replicableItems.length ? 'with' : 'without'
      } replicableItems`, () => {
        beforeEach(() => {
          wrapper.vm.$store.state.isLoading = isLoading;
          wrapper.vm.$store.state.replicableItems = replicableItems;
          wrapper.vm.$store.state.paginationData.total = replicableItems.length;
        });

        it(`${showReplicableItems ? 'shows' : 'hides'} the replicable items`, () => {
          expect(findGeoReplicable().exists()).toBe(showReplicableItems);
        });

        it(`${showEmptyState ? 'shows' : 'hides'} the empty state`, () => {
          expect(findGeoReplicableEmptyState().exists()).toBe(showEmptyState);
        });

        it(`${showFilterBar ? 'shows' : 'hides'} the filter bar`, () => {
          expect(findGeoReplicableFilterBar().exists()).toBe(showFilterBar);
        });

        it(`${showLoader ? 'shows' : 'hides'} the loader`, () => {
          expect(findGlLoadingIcon().exists()).toBe(showLoader);
        });
      });
    },
  );

  describe('onCreate', () => {
    beforeEach(() => {
      createStore();
      createComponent();
    });

    it('calls fetchReplicableItems', () => {
      expect(store.dispatch).toHaveBeenCalledWith('fetchReplicableItems');
    });
  });
});
