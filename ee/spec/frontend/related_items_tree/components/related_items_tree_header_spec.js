import { GlTooltip, GlIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';

import EpicHealthStatus from 'ee/related_items_tree/components/epic_health_status.vue';
import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_issue_actions_split_button.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import { issuableTypesMap } from '~/related_issues/constants';
import { mockInitialConfig, mockParentItem, mockQueryResponse } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = ({ slots } = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });
  store.dispatch('setChildrenCount', mockParentItem.descendantCounts);

  return shallowMount(RelatedItemsTreeHeader, {
    localVue,
    store,
    slots,
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeHeader', () => {
    let wrapper;

    const findEpicsIssuesSplitButton = () => wrapper.find(EpicActionsSplitButton);

    afterEach(() => {
      wrapper.destroy();
    });

    describe('badgeTooltip', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('returns string containing epic count based on available direct children within state', () => {
        expect(wrapper.find(GlTooltip).text()).toContain(`Epics •
        1 open, 1 closed`);
      });

      it('returns string containing issue count based on available direct children within state', () => {
        expect(wrapper.find(GlTooltip).text()).toContain(`Issues •
        2 open, 1 closed`);
      });
    });

    describe('epic issue actions split button', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('showAddEpicForm event', () => {
        let toggleAddItemForm;

        beforeEach(() => {
          toggleAddItemForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showAddEpicForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[0][1];

          expect(payload).toEqual({
            issuableType: issuableTypesMap.EPIC,
            toggleState: true,
          });
        });
      });

      describe('showCreateEpicForm event', () => {
        let toggleCreateEpicForm;

        beforeEach(() => {
          toggleCreateEpicForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateEpicForm,
            },
          });
        });

        it('dispatches toggleCreateEpicForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showCreateEpicForm');

          expect(toggleCreateEpicForm).toHaveBeenCalled();

          const payload =
            toggleCreateEpicForm.mock.calls[toggleCreateEpicForm.mock.calls.length - 1][1];

          expect(payload).toEqual({ toggleState: true });
        });
      });

      describe('showAddIssueForm event', () => {
        let toggleAddItemForm;
        let setItemInputValue;

        beforeEach(() => {
          toggleAddItemForm = jest.fn();
          setItemInputValue = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
              setItemInputValue,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showAddIssueForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[0][1];

          expect(payload).toEqual({
            issuableType: issuableTypesMap.ISSUE,
            toggleState: true,
          });
        });
      });

      describe('showCreateIssueForm event', () => {
        let toggleCreateIssueForm;

        beforeEach(() => {
          toggleCreateIssueForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateIssueForm,
            },
          });
        });

        it('dispatches toggleCreateIssueForm action', () => {
          findEpicsIssuesSplitButton().vm.$emit('showCreateIssueForm');

          expect(toggleCreateIssueForm).toHaveBeenCalled();

          const payload =
            toggleCreateIssueForm.mock.calls[toggleCreateIssueForm.mock.calls.length - 1][1];

          expect(payload).toEqual({ toggleState: true });
        });
      });
    });

    describe('template', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders item badges container', () => {
        const badgesContainerEl = wrapper.find('.issue-count-badge');

        expect(badgesContainerEl.isVisible()).toBe(true);
      });

      it('renders epics count and gl-icon', () => {
        const epicsEl = wrapper.findAll('.issue-count-badge > span').at(0);
        const epicIcon = epicsEl.find(GlIcon);

        expect(epicsEl.text().trim()).toContain('2');
        expect(epicIcon.isVisible()).toBe(true);
        expect(epicIcon.props('name')).toBe('epic');
      });

      it('renders `Add` dropdown button', () => {
        expect(findEpicsIssuesSplitButton().isVisible()).toBe(true);
      });

      describe('when issuable-health-status feature is not available', () => {
        beforeEach(() => {
          wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
            ...mockInitialConfig,
            allowIssuableHealthStatus: false,
          });

          return wrapper.vm.$nextTick();
        });

        it('does not render health status', () => {
          expect(wrapper.find(EpicHealthStatus).exists()).toBe(false);
        });
      });

      describe('when issuable-health-status feature is available', () => {
        beforeEach(() => {
          wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
            ...mockInitialConfig,
            allowIssuableHealthStatus: true,
          });

          return wrapper.vm.$nextTick();
        });

        it('does not render health status', () => {
          expect(wrapper.find(EpicHealthStatus).exists()).toBe(true);
        });
      });

      it('renders issues count and gl-icon', () => {
        const issuesEl = wrapper.findAll('.issue-count-badge > span').at(1);
        const issueIcon = issuesEl.find(GlIcon);

        expect(issuesEl.text().trim()).toContain('3');
        expect(issueIcon.isVisible()).toBe(true);
        expect(issueIcon.props('name')).toBe('issues');
      });
    });
  });
});
