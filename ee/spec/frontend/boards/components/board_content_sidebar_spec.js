import { mount } from '@vue/test-utils';
import { GlDrawer } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import BoardContentSidebar from 'ee_component/boards/components/board_content_sidebar.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import IssuableTitle from '~/boards/components/issuable_title.vue';
import { createStore } from '~/boards/stores';
import { ISSUABLE } from '~/boards/constants';

describe('ee/BoardContentSidebar', () => {
  let wrapper;
  let store;

  const createComponent = () => {
    wrapper = mount(BoardContentSidebar, {
      provide: {
        rootPath: '',
      },
      store,
      stubs: {
        'board-sidebar-epic-select': '<div></div>',
        'board-sidebar-time-tracker': '<div></div>',
        'board-sidebar-weight-input': '<div></div>',
        'board-sidebar-labels-select': '<div></div>',
        'board-sidebar-due-date': '<div></div>',
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    store.state.sidebarType = ISSUABLE;
    store.state.issues = { '1': { title: 'One', referencePath: 'path', assignees: [] } };
    store.state.activeId = '1';

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('confirms we render GlDrawer', () => {
    expect(wrapper.find(GlDrawer).exists()).toBe(true);
  });

  it('applies an open attribute', () => {
    expect(wrapper.find(GlDrawer).props('open')).toBe(true);
  });

  it('finds IssuableTitle', () => {
    expect(wrapper.find(IssuableTitle).text()).toContain('One');
  });

  it('renders IssuableAssignees', () => {
    expect(wrapper.find(IssuableAssignees).exists()).toBe(true);
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
