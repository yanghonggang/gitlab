import { GlAlert, GlLoadingIcon, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Iterations from 'ee/iterations/components/iterations.vue';
import IterationsList from 'ee/iterations/components/iterations_list.vue';
import { Namespace } from 'ee/iterations/constants';

describe('Iterations', () => {
  let wrapper;
  const defaultProps = {
    fullPath: 'gitlab-org',
  };

  const mountComponent = ({ props = defaultProps, loading = false } = {}) => {
    wrapper = shallowMount(Iterations, {
      propsData: props,
      mocks: {
        $apollo: {
          queries: { namespace: { loading } },
        },
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('hides list while loading', () => {
    mountComponent({
      loading: true,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
    expect(wrapper.find(IterationsList).exists()).toBeFalsy();
  });

  it('shows iterations list when not loading', () => {
    mountComponent({
      loading: false,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
    expect(wrapper.find(IterationsList).exists()).toBeTruthy();
  });

  it('sets computed state from tabIndex', () => {
    mountComponent();

    expect(wrapper.vm.state).toEqual('opened');

    wrapper.vm.tabIndex = 1;

    expect(wrapper.vm.state).toEqual('closed');

    wrapper.vm.tabIndex = 2;

    expect(wrapper.vm.state).toEqual('all');
  });

  describe('pagination', () => {
    const findPagination = () => wrapper.find(GlPagination);
    const setPage = page => {
      findPagination().vm.$emit('input', page);
      return findPagination().vm.$nextTick();
    };

    beforeEach(() => {
      mountComponent({
        loading: false,
      });
      wrapper.setData({
        namespace: {
          pageInfo: {
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor: 'first-item',
            endCursor: 'last-item',
          },
        },
      });
    });

    it('passes prev, next, and current page props', () => {
      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props()).toEqual(
        expect.objectContaining({
          value: wrapper.vm.pagination.currentPage,
          prevPage: wrapper.vm.prevPage,
          nextPage: wrapper.vm.nextPage,
        }),
      );
    });

    it('updates query variables when going to previous page', async () => {
      await setPage(1);

      expect(wrapper.vm.queryVariables).toEqual({
        beforeCursor: 'first-item',
        isGroup: true,
        lastPageSize: 20,
        fullPath: defaultProps.fullPath,
        state: 'opened',
      });
    });

    it('updates query variables when going to next page', async () => {
      await setPage(2);

      expect(wrapper.vm.queryVariables).toEqual({
        afterCursor: 'last-item',
        firstPageSize: 20,
        fullPath: defaultProps.fullPath,
        isGroup: true,
        state: 'opened',
      });
    });

    it('resets pagination when changing tabs', async () => {
      await setPage(2);

      expect(wrapper.vm.pagination).toEqual({
        currentPage: 2,
        afterCursor: 'last-item',
      });

      wrapper.find(GlTabs).vm.$emit('activate-tab', 2);

      await wrapper.vm.$nextTick();

      expect(wrapper.vm.pagination).toEqual({
        currentPage: 1,
      });
    });
  });

  describe('iterations query variables', () => {
    const expected = {
      afterCursor: undefined,
      firstPageSize: 20,
      fullPath: defaultProps.fullPath,
      state: 'opened',
    };

    describe('when group', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Group,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: true,
        });
      });
    });

    describe('when project', () => {
      it('has expected query variable values', () => {
        mountComponent({
          props: {
            ...defaultProps,
            namespaceType: Namespace.Project,
          },
        });

        expect(wrapper.vm.queryVariables).toEqual({
          ...expected,
          isGroup: false,
        });
      });
    });
  });

  describe('error', () => {
    beforeEach(() => {
      mountComponent({
        loading: false,
      });
      wrapper.setData({
        error: 'Oh no!',
      });
    });

    it('tab shows error in alert', () => {
      expect(wrapper.find(GlAlert).text()).toContain('Oh no!');
    });
  });
});
