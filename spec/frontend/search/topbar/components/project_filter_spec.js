import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { MOCK_PROJECT, MOCK_QUERY } from 'jest/search/mock_data';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import ProjectFilter from '~/search/topbar/components/project_filter.vue';
import SearchableDropdown from '~/search/topbar/components/searchable_dropdown.vue';
import { ANY_OPTION, PROJECT_DATA } from '~/search/topbar/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  setUrlParams: jest.fn(),
}));

describe('ProjectFilter', () => {
  let wrapper;

  const actionSpies = {
    fetchProjects: jest.fn(),
  };

  const defaultProps = {
    initialData: null,
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(ProjectFilter, {
      localVue,
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSearchableDropdown = () => wrapper.find(SearchableDropdown);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders SearchableDropdown always', () => {
      expect(findSearchableDropdown().exists()).toBe(true);
    });
  });

  describe('events', () => {
    describe('when @search is emitted', () => {
      const search = 'test';

      beforeEach(() => {
        createComponent();

        findSearchableDropdown().vm.$emit('search', search);
      });

      it('calls fetchProjects with the search paramter', () => {
        expect(actionSpies.fetchProjects).toHaveBeenCalledWith(expect.any(Object), search);
      });
    });

    describe('when @change is emitted', () => {
      beforeEach(() => {
        createComponent();

        findSearchableDropdown().vm.$emit('change', MOCK_PROJECT);
      });

      it('calls calls setUrlParams with project id and visitUrl', () => {
        expect(setUrlParams).toHaveBeenCalledWith({
          [PROJECT_DATA.queryParam]: MOCK_PROJECT.id,
        });
        expect(visitUrl).toHaveBeenCalled();
      });
    });
  });

  describe('computed', () => {
    describe('selectedProject', () => {
      describe('when initialData is null', () => {
        beforeEach(() => {
          createComponent();
        });

        it('sets selectedProject to ANY_OPTION', () => {
          expect(wrapper.vm.selectedProject).toBe(ANY_OPTION);
        });
      });

      describe('when initialData is set', () => {
        beforeEach(() => {
          createComponent({}, { initialData: MOCK_PROJECT });
        });

        it('sets selectedProject to the initialData', () => {
          expect(wrapper.vm.selectedProject).toBe(MOCK_PROJECT);
        });
      });
    });
  });
});
