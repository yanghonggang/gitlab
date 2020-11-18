import { mount, createLocalVue } from '@vue/test-utils';
import { GlDropdownItem, GlAvatarLink, GlAvatarLabeled, GlSearchBoxByType } from '@gitlab/ui';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import VueApollo from 'vue-apollo';
import BoardAssigneeDropdown from '~/boards/components/board_assignee_dropdown.vue';
import IssuableAssignees from '~/sidebar/components/assignees/issuable_assignees.vue';
import MultiSelectDropdown from '~/vue_shared/components/sidebar/multiselect_dropdown.vue';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import store from '~/boards/stores';
import getIssueParticipants from '~/vue_shared/components/sidebar/queries/getIssueParticipants.query.graphql';
import searchUsers from '~/boards/queries/users_search.query.graphql';
import { participants } from '../mock_data';

const localVue = createLocalVue();

localVue.use(VueApollo);

describe('BoardCardAssigneeDropdown', () => {
  let wrapper;
  let fakeApollo;
  let getIssueParticipantsSpy;
  let getSearchUsersSpy;

  const iid = '111';
  const activeIssueName = 'test';
  const anotherIssueName = 'hello';

  const createComponent = (search = '') => {
    wrapper = mount(BoardAssigneeDropdown, {
      data() {
        return {
          search,
          selected: store.getters.activeIssue.assignees,
          participants,
        };
      },
      store,
      provide: {
        canUpdate: true,
        rootPath: '',
      },
    });
  };

  const createComponentWithApollo = (search = '') => {
    fakeApollo = createMockApollo([
      [getIssueParticipants, getIssueParticipantsSpy],
      [searchUsers, getSearchUsersSpy],
    ]);

    wrapper = mount(BoardAssigneeDropdown, {
      localVue,
      apolloProvider: fakeApollo,
      data() {
        return {
          search,
          selected: store.getters.activeIssue.assignees,
          participants,
        };
      },
      store,
      provide: {
        canUpdate: true,
        rootPath: '',
      },
    });
  };

  const unassign = async () => {
    wrapper.find('[data-testid="unassign"]').trigger('click');

    await wrapper.vm.$nextTick();
  };

  const openDropdown = async () => {
    wrapper.find('[data-testid="edit-button"]').trigger('click');

    await wrapper.vm.$nextTick();
  };

  const findByText = text => {
    return wrapper.findAll(GlDropdownItem).wrappers.find(node => node.text().indexOf(text) === 0);
  };

  beforeEach(() => {
    store.state.activeId = '1';
    store.state.issues = {
      '1': {
        iid,
        assignees: [{ username: activeIssueName, name: activeIssueName, id: activeIssueName }],
      },
    };

    jest.spyOn(store, 'dispatch').mockResolvedValue();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      text
      ${anotherIssueName}
      ${activeIssueName}
    `('finds item with $text', ({ text }) => {
      const item = findByText(text);

      expect(item.exists()).toBe(true);
    });

    it('renders gl-avatar-link in gl-dropdown-item', () => {
      const item = findByText('hello');

      expect(item.find(GlAvatarLink).exists()).toBe(true);
    });

    it('renders gl-avatar-labeled in gl-avatar-link', () => {
      const item = findByText('hello');

      expect(
        item
          .find(GlAvatarLink)
          .find(GlAvatarLabeled)
          .exists(),
      ).toBe(true);
    });
  });

  describe('when selected users are present', () => {
    it('renders a divider', () => {
      createComponent();

      expect(wrapper.find('[data-testid="selected-user-divider"]').exists()).toBe(true);
    });
  });

  describe('when collapsed', () => {
    it('renders IssuableAssignees', () => {
      createComponent();

      expect(wrapper.find(IssuableAssignees).isVisible()).toBe(true);
      expect(wrapper.find(MultiSelectDropdown).isVisible()).toBe(false);
    });
  });

  describe('when dropdown is open', () => {
    beforeEach(async () => {
      createComponent();

      await openDropdown();
    });

    it('shows assignees dropdown', async () => {
      expect(wrapper.find(IssuableAssignees).isVisible()).toBe(false);
      expect(wrapper.find(MultiSelectDropdown).isVisible()).toBe(true);
    });

    it('shows the issue returned as the activeIssue', async () => {
      expect(findByText(activeIssueName).props('isChecked')).toBe(true);
    });

    describe('when "Unassign" is clicked', () => {
      it('unassigns assignees', async () => {
        await unassign();

        expect(findByText('Unassign').props('isChecked')).toBe(true);
      });
    });

    describe('when an unselected item is clicked', () => {
      beforeEach(async () => {
        await unassign();
      });

      it('assigns assignee in the dropdown', async () => {
        wrapper.find('[data-testid="item_test"]').trigger('click');

        await wrapper.vm.$nextTick();

        expect(findByText(activeIssueName).props('isChecked')).toBe(true);
      });

      it('calls setAssignees with username list', async () => {
        wrapper.find('[data-testid="item_test"]').trigger('click');

        await wrapper.vm.$nextTick();

        document.body.click();

        await wrapper.vm.$nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('setAssignees', [activeIssueName]);
      });
    });

    describe('when the user off clicks', () => {
      beforeEach(async () => {
        await unassign();

        document.body.click();

        await wrapper.vm.$nextTick();
      });

      it('calls setAssignees with username list', async () => {
        expect(store.dispatch).toHaveBeenCalledWith('setAssignees', []);
      });

      it('closes the dropdown', async () => {
        expect(wrapper.find(IssuableAssignees).isVisible()).toBe(true);
      });
    });
  });

  it('renders divider after unassign', () => {
    createComponent();

    expect(wrapper.find('[data-testid="unassign-divider"]').exists()).toBe(true);
  });

  it.each`
    assignees                                                                 | expected
    ${[{ id: 5, username: '', name: '' }]}                                    | ${'Assignee'}
    ${[{ id: 6, username: '', name: '' }, { id: 7, username: '', name: '' }]} | ${'2 Assignees'}
  `(
    'when assignees have a length of $assignees.length, it renders $expected',
    ({ assignees, expected }) => {
      store.state.issues['1'].assignees = assignees;

      createComponent();

      expect(wrapper.find(BoardEditableItem).props('title')).toBe(expected);
    },
  );

  describe('Apollo', () => {
    beforeEach(() => {
      getIssueParticipantsSpy = jest.fn().mockResolvedValue({
        data: {
          issue: {
            participants: {
              nodes: [
                {
                  username: 'participant',
                  name: 'participant',
                  webUrl: '',
                  avatarUrl: '',
                  id: '',
                },
              ],
            },
          },
        },
      });
      getSearchUsersSpy = jest.fn().mockResolvedValue({
        data: {
          users: {
            nodes: [{ username: 'root', name: 'root', webUrl: '', avatarUrl: '', id: '' }],
          },
        },
      });
    });

    describe('when search is empty', () => {
      beforeEach(() => {
        createComponentWithApollo();
      });

      it('calls getIssueParticipants', async () => {
        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();

        expect(getIssueParticipantsSpy).toHaveBeenCalledWith({ id: 'gid://gitlab/Issue/111' });
      });
    });

    describe('when search is not empty', () => {
      beforeEach(() => {
        createComponentWithApollo('search term');
      });

      it('calls searchUsers', async () => {
        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();

        expect(getSearchUsersSpy).toHaveBeenCalledWith({ search: 'search term' });
      });
    });
  });

  it('finds GlSearchBoxByType', async () => {
    createComponent();

    await openDropdown();

    expect(wrapper.find(GlSearchBoxByType).exists()).toBe(true);
  });
});
