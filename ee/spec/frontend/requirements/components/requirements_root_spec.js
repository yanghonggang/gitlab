import { shallowMount } from '@vue/test-utils';

import { GlPagination } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

import RequirementsRoot from 'ee/requirements/components/requirements_root.vue';
import RequirementsTabs from 'ee/requirements/components/requirements_tabs.vue';
import RequirementsLoading from 'ee/requirements/components/requirements_loading.vue';
import RequirementsEmptyState from 'ee/requirements/components/requirements_empty_state.vue';
import RequirementItem from 'ee/requirements/components/requirement_item.vue';

import createRequirement from 'ee/requirements/queries/createRequirement.mutation.graphql';
import updateRequirement from 'ee/requirements/queries/updateRequirement.mutation.graphql';

import { TEST_HOST } from 'helpers/test_constants';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import { deprecatedCreateFlash as createFlash } from '~/flash';

import {
  FilterState,
  mockRequirementsOpen,
  mockRequirementsCount,
  mockPageInfo,
  mockFilters,
} from '../mock_data';

jest.mock('ee/requirements/constants', () => ({
  DEFAULT_PAGE_SIZE: 2,
  FilterState: jest.requireActual('ee/requirements/constants').FilterState,
  AvailableSortOptions: jest.requireActual('ee/requirements/constants').AvailableSortOptions,
}));

jest.mock('~/flash');

const $toast = {
  show: jest.fn(),
};

const createComponent = ({
  projectPath = 'gitlab-org/gitlab-shell',
  initialFilterBy = FilterState.opened,
  initialRequirementsCount = mockRequirementsCount,
  showCreateRequirement = false,
  emptyStatePath = '/assets/illustrations/empty-state/requirements.svg',
  loading = false,
  canCreateRequirement = true,
  requirementsWebUrl = '/gitlab-org/gitlab-shell/-/requirements',
} = {}) =>
  shallowMount(RequirementsRoot, {
    propsData: {
      projectPath,
      initialFilterBy,
      initialRequirementsCount,
      showCreateRequirement,
      emptyStatePath,
      canCreateRequirement,
      requirementsWebUrl,
    },
    mocks: {
      $apollo: {
        queries: {
          requirements: {
            loading,
            list: [],
            pageInfo: {},
            refetch: jest.fn(),
          },
          requirementsCount: {
            ...initialRequirementsCount,
            refetch: jest.fn(),
          },
        },
        mutate: jest.fn(),
      },
      $toast,
    },
  });

describe('RequirementsRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('requirementsListEmpty', () => {
      it('returns `false` when `$apollo.queries.requirements.loading` is true', () => {
        const wrapperLoading = createComponent({ loading: true });

        expect(wrapperLoading.vm.requirementsListEmpty).toBe(false);

        wrapperLoading.destroy();
      });

      it('returns `false` when `requirements.list` is empty', () => {
        wrapper.setData({
          requirements: {
            list: [],
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.requirementsListEmpty).toBe(false);
        });
      });

      it('returns `true` when `requirementsCount` for current filterBy value is 0', () => {
        wrapper.setData({
          filterBy: FilterState.opened,
          requirementsCount: {
            OPENED: 0,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.requirementsListEmpty).toBe(true);
        });
      });
    });

    describe('totalRequirementsForCurrentTab', () => {
      it('returns number representing total requirements for current tab', () => {
        wrapper.setData({
          filterBy: FilterState.opened,
          requirementsCount: {
            OPENED: mockRequirementsCount.OPENED,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.totalRequirementsForCurrentTab).toBe(mockRequirementsCount.OPENED);
        });
      });
    });

    describe('showEmptyState', () => {
      it('returns `false` when `showCreateForm` is true', () => {
        wrapper.setData({
          showCreateForm: true,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showEmptyState).toBe(false);
        });
      });
    });

    describe('showPaginationControls', () => {
      it('returns `true` when totalRequirements is more than default page size', () => {
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          requirementsCount: mockRequirementsCount,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showPaginationControls).toBe(true);
        });
      });

      it('returns `false` when totalRequirements is less than default page size', () => {
        wrapper.setData({
          requirements: {
            list: [mockRequirementsOpen[0]],
            pageInfo: mockPageInfo,
          },
          requirementsCount: {
            ...mockRequirementsCount,
            OPENED: 1,
          },
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.showPaginationControls).toBe(false);
        });
      });

      it.each`
        hasPreviousPage | hasNextPage  | isVisible
        ${true}         | ${undefined} | ${true}
        ${undefined}    | ${true}      | ${true}
        ${false}        | ${undefined} | ${false}
        ${undefined}    | ${false}     | ${false}
        ${false}        | ${false}     | ${false}
        ${true}         | ${true}      | ${true}
      `(
        'returns $isVisible when hasPreviousPage is $hasPreviousPage and hasNextPage is $hasNextPage within `requirements.pageInfo`',
        ({ hasPreviousPage, hasNextPage, isVisible }) => {
          wrapper.setData({
            requirements: {
              pageInfo: {
                hasPreviousPage,
                hasNextPage,
              },
            },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.showPaginationControls).toBe(isVisible);
          });
        },
      );
    });

    describe('prevPage', () => {
      it('returns number representing previous page based on currentPage value', () => {
        wrapper.setData({
          currentPage: 3,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.prevPage).toBe(2);
        });
      });
    });

    describe('nextPage', () => {
      it('returns number representing next page based on currentPage value', () => {
        expect(wrapper.vm.nextPage).toBe(2);
      });

      it('returns `null` when currentPage is already last page', () => {
        wrapper.setData({
          currentPage: 2,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.nextPage).toBeNull();
        });
      });
    });
  });

  describe('methods', () => {
    const mockUpdateMutationResult = {
      data: {
        updateRequirement: {
          errors: [],
          requirement: {
            iid: '1',
            title: 'foo',
          },
        },
      },
    };

    describe('getFilteredSearchValue', () => {
      it('returns array containing applied filter search values', () => {
        wrapper.setData({
          authorUsernames: ['root', 'john.doe'],
          textSearch: 'foo',
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.getFilteredSearchValue()).toEqual(mockFilters);
        });
      });
    });

    describe('updateUrl', () => {
      it('updates window URL based on presence of props for filtered search and sort criteria', () => {
        wrapper.setData({
          filterBy: FilterState.all,
          currentPage: 2,
          nextPageCursor: mockPageInfo.endCursor,
          authorUsernames: ['root', 'john.doe'],
          textSearch: 'foo',
          sortBy: 'updated_asc',
        });

        return wrapper.vm.$nextTick(() => {
          wrapper.vm.updateUrl();

          expect(global.window.location.href).toBe(
            `${TEST_HOST}/?page=2&next=${mockPageInfo.endCursor}&state=all&search=foo&sort=updated_asc&author_username%5B%5D=root&author_username%5B%5D=john.doe`,
          );
        });
      });
    });

    describe('updateRequirement', () => {
      it('calls `$apollo.mutate` with `updateRequirement` mutation and variables containing `projectPath` & `iid`', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `title` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                title: 'foo',
              },
            },
          }),
        );
      });

      it('calls `$apollo.mutate` with variables containing `state` when it is included in object param', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.updateRequirement({
          iid: '1',
          state: FilterState.opened,
        });

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: updateRequirement,
            variables: {
              updateRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                iid: '1',
                state: FilterState.opened,
              },
            },
          }),
        );
      });

      it('calls `createFlash` with provided `errorFlashMessage` param and `Sentry.captureException` when request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(new Error());
        jest.spyOn(Sentry, 'captureException').mockImplementation();

        return wrapper.vm
          .updateRequirement({
            iid: '1',
            errorFlashMessage: 'Something went wrong',
          })
          .then(() => {
            expect(createFlash).toHaveBeenCalledWith('Something went wrong');
            expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Object));
          });
      });
    });

    describe('handleNewRequirementClick', () => {
      it('sets `showCreateForm` prop to `true`', () => {
        wrapper.vm.handleNewRequirementClick();

        expect(wrapper.vm.showCreateForm).toBe(true);
      });
    });

    describe('handleEditRequirementClick', () => {
      it('sets `showEditForm` prop to `true` and `editedRequirement` to value of passed param', () => {
        wrapper.vm.handleEditRequirementClick(mockRequirementsOpen[0]);

        expect(wrapper.vm.showEditForm).toBe(true);
        expect(wrapper.vm.editedRequirement).toBe(mockRequirementsOpen[0]);
      });
    });

    describe('handleNewRequirementSave', () => {
      const mockMutationResult = {
        data: {
          createRequirement: {
            errors: [],
            requirement: {
              iid: '1',
            },
          },
        },
      };

      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave('foo');

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `$apollo.mutate` with createRequirement mutation and `projectPath` & `title` as variables', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));

        wrapper.vm.handleNewRequirementSave('foo');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: createRequirement,
            variables: {
              createRequirementInput: {
                projectPath: 'gitlab-org/gitlab-shell',
                title: 'foo',
              },
            },
          }),
        );
      });

      it('sets `showCreateForm` and `createRequirementRequestActive` props to `false` and refetches requirements count and list when request is successful', () => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockReturnValue(Promise.resolve(mockMutationResult));
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirementsCount, 'refetch')
          .mockImplementation(jest.fn());
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirements, 'refetch')
          .mockImplementation(jest.fn());

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(wrapper.vm.$apollo.queries.requirementsCount.refetch).toHaveBeenCalled();
          expect(wrapper.vm.$apollo.queries.requirements.refetch).toHaveBeenCalled();
          expect(wrapper.vm.showCreateForm).toBe(false);
          expect(wrapper.vm.createRequirementRequestActive).toBe(false);
        });
      });

      it('calls `$toast.show` with string "Requirement added successfully" when request is successful', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockMutationResult);

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith('Requirement REQ-1 has been added');
        });
      });

      it('sets `createRequirementRequestActive` prop to `false` and calls `createFlash` when `$apollo.mutate` request fails', () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));

        return wrapper.vm.handleNewRequirementSave('foo').then(() => {
          expect(createFlash).toHaveBeenCalledWith(
            'Something went wrong while creating a requirement.',
          );
          expect(wrapper.vm.createRequirementRequestActive).toBe(false);
        });
      });
    });

    describe('handleUpdateRequirementSave', () => {
      it('sets `createRequirementRequestActive` prop to `true`', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          title: 'foo',
        });

        expect(wrapper.vm.createRequirementRequestActive).toBe(true);
      });

      it('calls `updateRequirement` with object containing `iid`, `title` & `errorFlashMessage` props', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        wrapper.vm.handleUpdateRequirementSave({
          iid: '1',
          title: 'foo',
        });

        expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
          expect.objectContaining({
            iid: '1',
            title: 'foo',
            errorFlashMessage: 'Something went wrong while updating a requirement.',
          }),
        );
      });

      it('sets `showEditForm` to `true`, `editedRequirement` to `null` and `createRequirementRequestActive` prop to `false` when request is successful', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        return wrapper.vm
          .handleUpdateRequirementSave({
            iid: '1',
            title: 'foo',
          })
          .then(() => {
            expect(wrapper.vm.showEditForm).toBe(false);
            expect(wrapper.vm.editedRequirement).toBe(null);
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });

      it('calls `$toast.show` with string "Requirement updated successfully" when request is successful', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);

        return wrapper.vm
          .handleUpdateRequirementSave({
            iid: '1',
            title: 'foo',
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been updated',
            );
          });
      });

      it('sets `createRequirementRequestActive` prop to `false` when request fails', () => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockRejectedValue(new Error());

        return wrapper.vm
          .handleUpdateRequirementSave({
            title: 'foo',
          })
          .catch(() => {
            expect(wrapper.vm.createRequirementRequestActive).toBe(false);
          });
      });
    });

    describe('handleNewRequirementCancel', () => {
      it('sets `showCreateForm` prop to `false`', () => {
        wrapper.setData({
          showCreateForm: true,
        });

        wrapper.vm.handleNewRequirementCancel();

        expect(wrapper.vm.showCreateForm).toBe(false);
      });
    });

    describe('handleRequirementStateChange', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'updateRequirement').mockResolvedValue(mockUpdateMutationResult);
      });

      it('sets `stateChangeRequestActiveFor` value to `iid` provided within object param', () => {
        wrapper.vm.handleRequirementStateChange({
          iid: '1',
        });

        expect(wrapper.vm.stateChangeRequestActiveFor).toBe('1');
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "OPENED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: FilterState.opened,
                errorFlashMessage: 'Something went wrong while reopening a requirement.',
              }),
            );
          });
      });

      it('calls `updateRequirement` with object containing params and errorFlashMessage when `params.state` is "ARCHIVED"', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.updateRequirement).toHaveBeenCalledWith(
              expect.objectContaining({
                iid: '1',
                state: FilterState.archived,
                errorFlashMessage: 'Something went wrong while archiving a requirement.',
              }),
            );
          });
      });

      it('sets `stateChangeRequestActiveFor` to 0', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.stateChangeRequestActiveFor).toBe(0);
          });
      });

      it('refetches requirementsCount query when request is successful', () => {
        jest
          .spyOn(wrapper.vm.$apollo.queries.requirementsCount, 'refetch')
          .mockImplementation(jest.fn());

        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.$apollo.queries.requirementsCount.refetch).toHaveBeenCalled();
          });
      });

      it('calls `$toast.show` with string "Requirement has been reopened" when `params.state` is "OPENED" and request is successful', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.opened,
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been reopened',
            );
          });
      });

      it('calls `$toast.show` with string "Requirement has been archived" when `params.state` is "ARCHIVED" and request is successful', () => {
        return wrapper.vm
          .handleRequirementStateChange({
            iid: '1',
            state: FilterState.archived,
          })
          .then(() => {
            expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(
              'Requirement REQ-1 has been archived',
            );
          });
      });
    });

    describe('handleUpdateRequirementCancel', () => {
      it('sets `showEditForm` prop to `false` and `editedRequirement` to `null`', () => {
        wrapper.vm.handleUpdateRequirementCancel();

        expect(wrapper.vm.showEditForm).toBe(false);
        expect(wrapper.vm.editedRequirement).toBe(null);
      });
    });

    describe('handleFilterRequirements', () => {
      it('updates props tied to requirements Graph query', () => {
        wrapper.vm.handleFilterRequirements(mockFilters);

        expect(wrapper.vm.authorUsernames).toEqual(['root', 'john.doe']);
        expect(wrapper.vm.textSearch).toBe('foo');
        expect(wrapper.vm.currentPage).toBe(1);
        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe('');
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&search=foo&sort=created_desc&author_username%5B%5D=root&author_username%5B%5D=john.doe`,
        );
      });

      it('updates props `textSearch` and `authorUsernames` with empty values when passed filters param is empty', () => {
        wrapper.setData({
          authorUsernames: ['foo'],
          textSearch: 'bar',
        });

        wrapper.vm.handleFilterRequirements([]);

        expect(wrapper.vm.authorUsernames).toEqual([]);
        expect(wrapper.vm.textSearch).toBe('');
      });
    });

    describe('handleSortRequirements', () => {
      it('updates props tied to requirements Graph query', () => {
        wrapper.vm.handleSortRequirements('updated_desc');

        expect(wrapper.vm.sortBy).toBe('updated_desc');
        expect(wrapper.vm.currentPage).toBe(1);
        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe('');
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&sort=updated_desc`,
        );
      });
    });

    describe('handlePageChange', () => {
      it('sets data prop `prevPageCursor` to empty string and `nextPageCursor` to `requirements.pageInfo.endCursor` when provided page param is greater than currentPage', () => {
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          currentPage: 1,
          requirementsCount: mockRequirementsCount,
        });

        wrapper.vm.handlePageChange(2);

        expect(wrapper.vm.prevPageCursor).toBe('');
        expect(wrapper.vm.nextPageCursor).toBe(mockPageInfo.endCursor);
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=2&state=opened&sort=created_desc&next=${mockPageInfo.endCursor}`,
        );
      });

      it('sets data prop `nextPageCursor` to empty string and `prevPageCursor` to `requirements.pageInfo.startCursor` when provided page param is less than currentPage', () => {
        wrapper.setData({
          requirements: {
            list: mockRequirementsOpen,
            pageInfo: mockPageInfo,
          },
          currentPage: 2,
          requirementsCount: mockRequirementsCount,
        });

        wrapper.vm.handlePageChange(1);

        expect(wrapper.vm.prevPageCursor).toBe(mockPageInfo.startCursor);
        expect(wrapper.vm.nextPageCursor).toBe('');
        expect(global.window.location.href).toBe(
          `${TEST_HOST}/?page=1&state=opened&sort=created_desc&prev=${mockPageInfo.startCursor}`,
        );
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `requirements-list-container`', () => {
      expect(wrapper.classes()).toContain('requirements-list-container');
    });

    it('renders requirements-tabs component', () => {
      expect(wrapper.find(RequirementsTabs).exists()).toBe(true);
    });

    it('renders filtered-search-bar component', () => {
      expect(wrapper.find(FilteredSearchBarRoot).exists()).toBe(true);
      expect(wrapper.find(FilteredSearchBarRoot).props('searchInputPlaceholder')).toBe(
        'Search requirements',
      );
      expect(wrapper.find(FilteredSearchBarRoot).props('tokens')).toEqual([
        {
          type: 'author_username',
          icon: 'user',
          title: 'Author',
          unique: false,
          symbol: '@',
          token: AuthorToken,
          operators: [{ value: '=', description: 'is', default: 'true' }],
          fetchPath: 'gitlab-org/gitlab-shell',
          fetchAuthors: expect.any(Function),
        },
      ]);
      expect(wrapper.find(FilteredSearchBarRoot).props('recentSearchesStorageKey')).toBe(
        'requirements',
      );
    });

    it('renders empty state when query results are empty', () => {
      wrapper.setData({
        requirements: {
          list: [],
        },
        requirementsCount: {
          OPENED: 0,
        },
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(RequirementsEmptyState).exists()).toBe(true);
      });
    });

    it('renders requirements-loading component when query results are still being loaded', () => {
      const wrapperLoading = createComponent({ loading: true });

      expect(wrapperLoading.find(RequirementsLoading).isVisible()).toBe(true);

      wrapperLoading.destroy();
    });

    it('renders requirement-create-form component', () => {
      expect(wrapper.find('requirement-create-form-stub').exists()).toBe(true);
    });

    it('renders requirement-edit-form component', () => {
      expect(wrapper.find('requirement-edit-form-stub').exists()).toBe(true);
    });

    it('does not render requirement-empty-state component when `showCreateForm` prop is `true`', () => {
      wrapper.setData({
        showCreateForm: true,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(RequirementsEmptyState).exists()).toBe(false);
      });
    });

    it('renders requirement items for all the requirements', () => {
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          pageInfo: mockPageInfo,
        },
        requirementsCount: mockRequirementsCount,
      });

      return wrapper.vm.$nextTick(() => {
        const itemsContainer = wrapper.find('ul.requirements-list');

        expect(itemsContainer.exists()).toBe(true);
        expect(itemsContainer.findAll(RequirementItem)).toHaveLength(mockRequirementsOpen.length);
      });
    });

    it('renders pagination controls', () => {
      wrapper.setData({
        requirements: {
          list: mockRequirementsOpen,
          pageInfo: mockPageInfo,
        },
        requirementsCount: mockRequirementsCount,
      });

      return wrapper.vm.$nextTick(() => {
        const pagination = wrapper.find(GlPagination);

        expect(pagination.exists()).toBe(true);
        expect(pagination.props('value')).toBe(1);
        expect(pagination.props('perPage')).toBe(2); // We're mocking this page size
        expect(pagination.props('align')).toBe('center');
      });
    });
  });
});
