import { shallowMount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import BoardContentSidebar from 'ee_component/boards/components/board_content_sidebar.vue';
import { createStore } from '~/boards/stores';
import { ISSUABLE } from '~/boards/constants';

describe('ee/BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = shallowMount(BoardContentSidebar, {
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.state.sidebarType = ISSUABLE;
    store.state.activeId = 1;

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.find(GlDrawer).exists()).toBe(true);
  });

  it('applies an open attribute', () => {
    expect(wrapper.find(GlDrawer).props('open')).toBe(true);
  });

  describe('when we emit close', () => {
    it('hides GlDrawer', async () => {
      expect(wrapper.find(GlDrawer).props('open')).toBe(true);

      wrapper.find(GlDrawer).vm.$emit('close');

      await waitForPromises();

      expect(wrapper.find(GlDrawer).exists()).toBe(false);
    });
  });
});