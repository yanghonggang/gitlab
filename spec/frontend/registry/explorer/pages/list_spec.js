import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlSprintf, GlAlert, GlSearchBoxByClick } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Tracking from '~/tracking';
import component from '~/registry/explorer/pages/list.vue';
import CliCommands from '~/registry/explorer/components/list_page/cli_commands.vue';
import GroupEmptyState from '~/registry/explorer/components/list_page/group_empty_state.vue';
import ProjectEmptyState from '~/registry/explorer/components/list_page/project_empty_state.vue';
import RegistryHeader from '~/registry/explorer/components/list_page/registry_header.vue';
import ImageList from '~/registry/explorer/components/list_page/image_list.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { createStore } from '~/registry/explorer/stores/';
import { SET_INITIAL_STATE } from '~/registry/explorer/stores/mutation_types';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  IMAGE_REPOSITORY_LIST_LABEL,
  SEARCH_PLACEHOLDER_TEXT,
} from '~/registry/explorer/constants';

import getProjectContainerRepositories from '~/registry/explorer/graphql/queries/get_project_container_repositories.graphql';
import getGroupContainerRepositories from '~/registry/explorer/graphql/queries/get_group_container_repositories.graphql';
import deleteContainerRepository from '~/registry/explorer/graphql/mutations/delete_container_repository.graphql';

import {
  graphQLImageListMock,
  graphQLImageDeleteMock,
  deletedContainerRepository,
  graphQLImageDeleteMockError,
  graphQLEmptyImageListMock,
  graphQLEmptyGroupImageListMock,
  pageInfo,
} from '../mock_data';
import { GlModal, GlEmptyState } from '../stubs';
import { $toast } from '../../shared/mocks';

const localVue = createLocalVue();

describe('List Page', () => {
  let wrapper;
  let store;
  let apolloProvider;

  const findDeleteModal = () => wrapper.find(GlModal);
  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);

  const findEmptyState = () => wrapper.find(GlEmptyState);

  const findCliCommands = () => wrapper.find(CliCommands);
  const findProjectEmptyState = () => wrapper.find(ProjectEmptyState);
  const findGroupEmptyState = () => wrapper.find(GroupEmptyState);
  const findRegistryHeader = () => wrapper.find(RegistryHeader);

  const findDeleteAlert = () => wrapper.find(GlAlert);
  const findImageList = () => wrapper.find(ImageList);
  const findListHeader = () => wrapper.find('[data-testid="listHeader"]');
  const findSearchBox = () => wrapper.find(GlSearchBoxByClick);
  const findEmptySearchMessage = () => wrapper.find('[data-testid="emptySearch"]');

  const waitForApolloRequestRender = async () => {
    await waitForPromises();
    await wrapper.vm.$nextTick();
  };

  const mountComponent = ({
    mocks,
    resolver = jest.fn().mockResolvedValue(graphQLImageListMock),
    groupResolver = jest.fn().mockResolvedValue(graphQLImageListMock),
    mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock),
  } = {}) => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getProjectContainerRepositories, resolver],
      [getGroupContainerRepositories, groupResolver],
      [deleteContainerRepository, mutationResolver],
    ];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      localVue,
      apolloProvider,
      store,
      stubs: {
        GlModal,
        GlEmptyState,
        GlSprintf,
        RegistryHeader,
        TitleArea,
      },
      mocks: {
        $toast,
        $route: {
          name: 'foo',
        },
        ...mocks,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('contains registry header', () => {
    mountComponent();

    expect(findRegistryHeader().exists()).toBe(true);
  });

  describe('connection error', () => {
    const config = {
      characterError: true,
      containersErrorImage: 'foo',
      helpPagePath: 'bar',
    };

    beforeEach(() => {
      store.commit(SET_INITIAL_STATE, config);
    });

    afterEach(() => {
      store.commit(SET_INITIAL_STATE, {});
    });

    it('should show an empty state', () => {
      mountComponent();

      expect(findEmptyState().exists()).toBe(true);
    });

    it('empty state should have an svg-path', () => {
      mountComponent();

      expect(findEmptyState().attributes('svg-path')).toBe(config.containersErrorImage);
    });

    it('empty state should have a description', () => {
      mountComponent();

      expect(findEmptyState().html()).toContain('connection error');
    });

    it('should not show the loading or default state', () => {
      mountComponent();

      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findImageList().exists()).toBe(false);
    });
  });

  describe('isLoading is true', () => {
    it('shows the skeleton loader', () => {
      mountComponent();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('imagesList is not visible', () => {
      mountComponent();

      expect(findImageList().exists()).toBe(false);
    });

    it('cli commands is not visible', () => {
      mountComponent();

      expect(findCliCommands().exists()).toBe(false);
    });
  });

  describe('list is empty', () => {
    describe('project page', () => {
      const resolver = jest.fn().mockResolvedValue(graphQLEmptyImageListMock);

      it('cli commands is not visible', async () => {
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(false);
      });

      it('project empty state is visible', async () => {
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        expect(findProjectEmptyState().exists()).toBe(true);
      });
    });
    describe('group page', () => {
      const groupResolver = jest.fn().mockResolvedValue(graphQLEmptyGroupImageListMock);

      beforeEach(() => {
        store.commit(SET_INITIAL_STATE, { isGroupPage: true });
      });

      afterEach(() => {
        store.commit(SET_INITIAL_STATE, { isGroupPage: undefined });
      });

      it('group empty state is visible', async () => {
        mountComponent({ groupResolver });

        await waitForApolloRequestRender();

        expect(findGroupEmptyState().exists()).toBe(true);
      });

      it('cli commands is not visible', async () => {
        mountComponent({ groupResolver });

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(false);
      });

      it('list header is not visible', async () => {
        mountComponent({ groupResolver });

        await waitForApolloRequestRender();

        expect(findListHeader().exists()).toBe(false);
      });
    });
  });

  describe('list is not empty', () => {
    describe('unfiltered state', () => {
      it('quick start is visible', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        expect(findCliCommands().exists()).toBe(true);
      });

      it('list component is visible', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        expect(findImageList().exists()).toBe(true);
      });

      it('list header is  visible', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        const header = findListHeader();
        expect(header.exists()).toBe(true);
        expect(header.text()).toBe(IMAGE_REPOSITORY_LIST_LABEL);
      });

      describe('delete image', () => {
        const deleteImage = async () => {
          await wrapper.vm.$nextTick();

          findImageList().vm.$emit('delete', deletedContainerRepository);
          findDeleteModal().vm.$emit('ok');

          await waitForApolloRequestRender();
        };

        it('should call deleteItem when confirming deletion', async () => {
          const mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock);
          mountComponent({ mutationResolver });

          await deleteImage();

          expect(wrapper.vm.itemToDelete).toEqual(deletedContainerRepository);
          expect(mutationResolver).toHaveBeenCalledWith({ id: deletedContainerRepository.id });

          const updatedImage = findImageList()
            .props('images')
            .find(i => i.id === deletedContainerRepository.id);

          expect(updatedImage.status).toBe(deletedContainerRepository.status);
        });

        it('should show a success alert when delete request is successful', async () => {
          const mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMock);
          mountComponent({ mutationResolver });

          await deleteImage();

          const alert = findDeleteAlert();
          expect(alert.exists()).toBe(true);
          expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
            DELETE_IMAGE_SUCCESS_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
          );
        });

        describe('when delete request fails it shows an alert', () => {
          it('user recoverable error', async () => {
            const mutationResolver = jest.fn().mockResolvedValue(graphQLImageDeleteMockError);
            mountComponent({ mutationResolver });

            await deleteImage();

            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_ERROR_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });

          it('network error', async () => {
            const mutationResolver = jest.fn().mockRejectedValue();
            mountComponent({ mutationResolver });

            await deleteImage();

            const alert = findDeleteAlert();
            expect(alert.exists()).toBe(true);
            expect(alert.text().replace(/\s\s+/gm, ' ')).toBe(
              DELETE_IMAGE_ERROR_MESSAGE.replace('%{title}', wrapper.vm.itemToDelete.path),
            );
          });
        });
      });
    });

    describe('search', () => {
      const doSearch = async () => {
        await waitForApolloRequestRender();
        findSearchBox().vm.$emit('submit', 'centos6');
        await wrapper.vm.$nextTick();
      };

      it('has a search box element', async () => {
        mountComponent();

        await waitForApolloRequestRender();

        const searchBox = findSearchBox();
        expect(searchBox.exists()).toBe(true);
        expect(searchBox.attributes('placeholder')).toBe(SEARCH_PLACEHOLDER_TEXT);
      });

      it('performs a search', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await doSearch();

        expect(resolver).toHaveBeenCalledWith(expect.objectContaining({ name: 'centos6' }));
      });

      it('when search result is empty displays an empty search message', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        resolver.mockResolvedValue(graphQLEmptyImageListMock);

        await doSearch();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('pagination', () => {
      it('prev-page event triggers a fetchMore request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        findImageList().vm.$emit('prev-page');

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({ first: null, before: pageInfo.startCursor }),
        );
      });

      it('next-page event triggers a fetchMore request', async () => {
        const resolver = jest.fn().mockResolvedValue(graphQLImageListMock);
        mountComponent({ resolver });

        await waitForApolloRequestRender();

        findImageList().vm.$emit('next-page');

        expect(resolver).toHaveBeenCalledWith(
          expect.objectContaining({ after: pageInfo.endCursor }),
        );
      });
    });
  });

  describe('modal', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('exists', () => {
      expect(findDeleteModal().exists()).toBe(true);
    });

    it('contains a description with the path of the item to delete', () => {
      findImageList().vm.$emit('delete', { path: 'foo' });
      return wrapper.vm.$nextTick().then(() => {
        expect(findDeleteModal().html()).toContain('foo');
      });
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      mountComponent();
    });

    const testTrackingCall = action => {
      expect(Tracking.event).toHaveBeenCalledWith(undefined, action, {
        label: 'registry_repository_delete',
      });
    };

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
    });

    it('send an event when delete button is clicked', () => {
      findImageList().vm.$emit('delete', {});

      testTrackingCall('click_button');
    });

    it('send an event when cancel is pressed on modal', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('cancel');
      testTrackingCall('cancel_delete');
    });

    it('send an event when confirm is clicked on modal', () => {
      const deleteModal = findDeleteModal();
      deleteModal.vm.$emit('ok');
      testTrackingCall('confirm_delete');
    });
  });
});
