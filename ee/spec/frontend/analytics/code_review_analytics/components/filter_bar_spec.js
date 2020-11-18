import { createLocalVue, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import FilterBar from 'ee/analytics/code_review_analytics/components/filter_bar.vue';
import storeConfig from 'ee/analytics/code_review_analytics/store';
import {
  filterMilestones,
  filterLabels,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/mock_data';
import {
  getFilterParams,
  getFilterValues,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/test_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import * as utils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import initialFiltersState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';
import UrlSync from '~/vue_shared/components/url_sync.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const milestoneTokenType = 'milestone';
const labelsTokenType = 'labels';

const initialFilterBarState = {
  selectedMilestone: null,
  selectedLabelList: null,
};

const defaultParams = {
  milestone_title: null,
  'not[milestone_title]': null,
  label_name: null,
  'not[label_name]': null,
};

async function shouldMergeUrlParams(wrapper, result) {
  await wrapper.vm.$nextTick();
  expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(result, window.location.href, {
    spreadArrays: true,
  });
  expect(commonUtils.historyPushState).toHaveBeenCalled();
}

const selectedMilestoneParams = getFilterParams(filterMilestones);
const unselectedMilestoneParams = getFilterParams(filterMilestones, { operator: '!=' });
const selectedLabelParams = getFilterParams(filterLabels);
const unselectedLabelParams = getFilterParams(filterLabels, { operator: '!=' });

const milestoneValues = getFilterValues(filterMilestones);
const labelValues = getFilterValues(filterLabels);

describe('Filter bar', () => {
  let wrapper;
  let vuexStore;
  let mock;

  let setFiltersMock;

  const createStore = (initialState = {}) => {
    setFiltersMock = jest.fn();

    return new Vuex.Store({
      modules: {
        filters: {
          namespaced: true,
          state: {
            ...initialFiltersState(),
            ...initialState,
          },
          actions: {
            setFilters: setFiltersMock,
          },
        },
      },
    });
  };

  function createComponent(initialStore) {
    return shallowMount(FilterBar, {
      localVue,
      store: initialStore,
      propsData: {
        projectPath: 'foo',
      },
      stubs: {
        UrlSync,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  const findFilteredSearch = () => wrapper.find(FilteredSearchBar);
  const getSearchToken = type =>
    findFilteredSearch()
      .props('tokens')
      .find(token => token.type === type);

  describe('default', () => {
    beforeEach(() => {
      vuexStore = createStore();
      wrapper = createComponent(vuexStore);
    });

    it('renders FilteredSearchBar component', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
      });
      wrapper = createComponent(vuexStore);
    });

    it('displays the milestone and label token', () => {
      const tokens = findFilteredSearch().props('tokens');

      expect(tokens).toHaveLength(2);
      expect(tokens[0].type).toBe(milestoneTokenType);
      expect(tokens[1].type).toBe(labelsTokenType);
    });

    it('provides the initial milestone token', () => {
      const { initialMilestones: milestoneToken } = getSearchToken(milestoneTokenType);

      expect(milestoneToken).toHaveLength(filterMilestones.length);
    });

    it('provides the initial label token', () => {
      const { initialLabels: labelToken } = getSearchToken(labelsTokenType);

      expect(labelToken).toHaveLength(filterLabels.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      vuexStore = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
      });
      wrapper = createComponent(vuexStore);
      jest.spyOn(utils, 'processFilters');
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      const filters = [
        { type: 'milestone', value: getFilterParams(filterMilestones, { key: 'data' })[2] },
        { type: 'labels', value: getFilterParams(filterLabels, { key: 'data' })[2] },
        {
          type: 'labels',
          value: getFilterParams(filterLabels, { key: 'data', operator: '!=' })[4],
        },
      ];

      findFilteredSearch().vm.$emit('onFilter', filters);

      expect(utils.processFilters).toHaveBeenCalledWith(filters);

      expect(setFiltersMock).toHaveBeenCalledWith(expect.anything(), {
        selectedMilestone: selectedMilestoneParams[2],
        selectedLabelList: [selectedLabelParams[2], unselectedLabelParams[4]],
      });
    });
  });

  describe.each`
    stateKey               | payload                         | paramKey                  | value
    ${'selectedMilestone'} | ${selectedMilestoneParams[3]}   | ${'milestone_title'}      | ${milestoneValues[3]}
    ${'selectedMilestone'} | ${unselectedMilestoneParams[0]} | ${'not[milestone_title]'} | ${milestoneValues[0]}
    ${'selectedLabelList'} | ${selectedLabelParams}          | ${'label_name'}           | ${labelValues}
    ${'selectedLabelList'} | ${unselectedLabelParams}        | ${'not[label_name]'}      | ${labelValues}
  `(
    'with a $stateKey updates the $paramKey url parameter',
    ({ stateKey, payload, paramKey, value }) => {
      beforeEach(() => {
        commonUtils.historyPushState = jest.fn();
        urlUtils.mergeUrlParams = jest.fn();

        mock = new MockAdapter(axios);
        wrapper = createComponent(storeConfig);

        wrapper.vm.$store.dispatch('filters/setFilters', {
          ...initialFilterBarState,
          [stateKey]: payload,
        });
      });
      it(`sets the ${paramKey} url parameter`, async () => {
        await shouldMergeUrlParams(wrapper, {
          ...defaultParams,
          [paramKey]: value,
        });
      });
    },
  );
});
