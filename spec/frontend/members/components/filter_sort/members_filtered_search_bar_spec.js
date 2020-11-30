import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlFilteredSearchToken } from '@gitlab/ui';
import MembersFilteredSearchBar from '~/members/components/filter_sort/members_filtered_search_bar.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MembersFilteredSearchBar', () => {
  let wrapper;

  const createComponent = state => {
    const store = new Vuex.Store({
      state: {
        sourceId: 1,
        filteredSearchBar: {
          show: true,
          tokens: ['two_factor'],
          searchParam: 'search',
          placeholder: 'Filter members',
          recentSearchesStorageKey: 'group_members',
        },
        canManageMembers: true,
        ...state,
      },
    });

    wrapper = shallowMount(MembersFilteredSearchBar, {
      localVue,
      store,
    });
  };

  const findFilteredSearchBar = () => wrapper.find(FilteredSearchBar);

  it('passes correct props to `FilteredSearchBar` component', () => {
    createComponent();

    expect(findFilteredSearchBar().props()).toEqual(
      expect.objectContaining({
        namespace: '1',
        recentSearchesStorageKey: 'group_members',
        searchInputPlaceholder: 'Filter members',
      }),
    );
  });

  describe('filtering tokens', () => {
    it('includes tokens set in `filteredSearchBar.tokens`', () => {
      createComponent();

      expect(findFilteredSearchBar().props('tokens')).toEqual([
        {
          type: 'two_factor',
          icon: 'lock',
          title: '2FA',
          token: GlFilteredSearchToken,
          unique: true,
          operators: [{ value: '=', description: 'is' }],
          options: [
            { value: 'enabled', title: 'Enabled' },
            { value: 'disabled', title: 'Disabled' },
          ],
          requiredPermissions: 'canManageMembers',
        },
      ]);
    });

    describe('when `canManageMembers` is false', () => {
      it('excludes 2FA token', () => {
        createComponent({
          filteredSearchBar: {
            show: true,
            tokens: ['two_factor', 'with_inherited_permissions'],
            searchParam: 'search',
            placeholder: 'Filter members',
            recentSearchesStorageKey: 'group_members',
          },
          canManageMembers: false,
        });

        expect(findFilteredSearchBar().props('tokens')).toEqual([
          {
            type: 'with_inherited_permissions',
            icon: 'group',
            title: 'Membership',
            token: GlFilteredSearchToken,
            unique: true,
            operators: [{ value: '=', description: 'is' }],
            options: [{ value: 'exclude', title: 'Direct' }, { value: 'only', title: 'Inherited' }],
          },
        ]);
      });
    });
  });

  describe('when filters are set via query params', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL('https://localhost');
    });

    it('parses and passes tokens to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      window.location.search = '?two_factor=enabled&token_not_available=foobar';

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: 'two_factor',
          value: {
            data: 'enabled',
            operator: '=',
          },
        },
      ]);
    });

    it('parses and passes search param to `FilteredSearchBar` component as `initialFilterValue` prop', () => {
      window.location.search = '?search=foobar';

      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([
        {
          type: 'filtered-search-term',
          value: {
            data: 'foobar',
          },
        },
      ]);
    });
  });

  describe('when filter bar is submitted', () => {
    beforeEach(() => {
      delete window.location;
      window.location = new URL('https://localhost');
    });

    it('adds correct filter query params', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?two_factor=enabled');
    });

    it('adds search query param', () => {
      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
        { type: 'filtered-search-term', value: { data: 'foobar' } },
      ]);

      expect(window.location.href).toBe('https://localhost/?two_factor=enabled&search=foobar');
    });

    it('adds sort query param', () => {
      window.location.search = '?sort=name_asc';

      createComponent();

      findFilteredSearchBar().vm.$emit('onFilter', [
        { type: 'two_factor', value: { data: 'enabled', operator: '=' } },
        { type: 'filtered-search-term', value: { data: 'foobar' } },
      ]);

      expect(window.location.href).toBe(
        'https://localhost/?two_factor=enabled&search=foobar&sort=name_asc',
      );
    });
  });
});
