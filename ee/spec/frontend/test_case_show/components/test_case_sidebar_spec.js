import { shallowMount } from '@vue/test-utils';
import { GlButton, GlIcon } from '@gitlab/ui';
import Mousetrap from 'mousetrap';

import { mockCurrentUserTodo, mockLabels } from 'jest/issuable_list/mock_data';

import TestCaseSidebar from 'ee/test_case_show/components/test_case_sidebar.vue';

import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

import { mockProvide, mockTestCase } from '../mock_data';

const createComponent = ({
  sidebarExpanded = true,
  todo = mockCurrentUserTodo,
  selectedLabels = mockLabels,
  testCaseLoading = false,
} = {}) =>
  shallowMount(TestCaseSidebar, {
    provide: {
      ...mockProvide,
    },
    propsData: {
      sidebarExpanded,
      todo,
      selectedLabels,
    },
    mocks: {
      $apollo: {
        queries: {
          testCase: {
            loading: testCaseLoading,
          },
        },
      },
    },
  });

describe('TestCaseSidebar', () => {
  let mousetrapSpy;
  let wrapper;

  beforeEach(() => {
    mousetrapSpy = jest.spyOn(Mousetrap, 'bind');
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe.each`
      state        | isTodoPending | todoActionText    | todoIcon
      ${'pending'} | ${true}       | ${'Mark as done'} | ${'todo-done'}
      ${'done'}    | ${false}      | ${'Add a to do'}  | ${'todo-add'}
    `('when `todo.state` is "$state"', ({ state, isTodoPending, todoActionText, todoIcon }) => {
      beforeEach(async () => {
        wrapper.setProps({
          todo: {
            ...mockCurrentUserTodo,
            state,
          },
        });

        await wrapper.vm.$nextTick();
      });

      it.each`
        propName            | propValue
        ${'isTodoPending'}  | ${isTodoPending}
        ${'todoActionText'} | ${todoActionText}
        ${'todoIcon'}       | ${todoIcon}
      `('computed prop `$propName` returns $propValue', ({ propName, propValue }) => {
        expect(wrapper.vm[propName]).toBe(propValue);
      });
    });
  });

  describe('mounted', () => {
    it('binds key-press listener for `l` on Mousetrap', () => {
      expect(mousetrapSpy).toHaveBeenCalledWith('l', wrapper.vm.handleLabelsCollapsedButtonClick);
    });
  });

  describe('methods', () => {
    describe('handleTodoButtonClick', () => {
      it.each`
        state        | methodToCall
        ${'pending'} | ${'markTestCaseTodoDone'}
        ${'done'}    | ${'addTestCaseAsTodo'}
      `(
        'calls `wrapper.vm.$methodToCall` when `todo.state` is "$state"',
        async ({ state, methodToCall }) => {
          jest.spyOn(wrapper.vm, methodToCall).mockImplementation(jest.fn());
          wrapper.setProps({
            todo: {
              ...mockCurrentUserTodo,
              state,
            },
          });

          await wrapper.vm.$nextTick();

          wrapper.vm.handleTodoButtonClick();

          expect(wrapper.vm[methodToCall]).toHaveBeenCalled();
        },
      );
    });

    describe('toggleSidebar', () => {
      beforeEach(() => {
        setFixtures('<button class="js-toggle-right-sidebar-button"></button>');
      });

      it('dispatches click event on sidebar toggle button', () => {
        const buttonEl = document.querySelector('.js-toggle-right-sidebar-button');

        jest.spyOn(buttonEl, 'dispatchEvent');

        wrapper.vm.toggleSidebar();

        expect(buttonEl.dispatchEvent).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'click',
          }),
        );
      });
    });

    describe('handleLabelsDropdownClose', () => {
      it('sets `sidebarExpandedOnClick` to false and calls `toggleSidebar` method when `sidebarExpandedOnClick` is true', async () => {
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        wrapper.setData({
          sidebarExpandedOnClick: true,
        });

        await wrapper.vm.$nextTick();

        wrapper.vm.handleLabelsDropdownClose();

        expect(wrapper.vm.sidebarExpandedOnClick).toBe(false);
        expect(wrapper.vm.toggleSidebar).toHaveBeenCalled();
      });
    });

    describe('handleLabelsCollapsedButtonClick', () => {
      beforeEach(() => {
        setFixtures(`
          <div class="js-labels-block">
            <button class="js-sidebar-dropdown-toggle"></button>
          </div>
        `);
      });

      it('calls `toggleSidebar` method and sets `sidebarExpandedOnClick` to true when `sidebarExpanded` prop is false', async () => {
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        wrapper.setProps({
          sidebarExpanded: false,
        });

        await wrapper.vm.$nextTick();

        wrapper.vm.handleLabelsCollapsedButtonClick();

        expect(wrapper.vm.toggleSidebar).toHaveBeenCalled();
        expect(wrapper.vm.sidebarExpandedOnClick).toBe(true);
      });

      it('dispatches click event on label edit button', async () => {
        const buttonEl = document.querySelector('.js-sidebar-dropdown-toggle');
        jest.spyOn(wrapper.vm, 'toggleSidebar').mockImplementation(jest.fn());
        jest.spyOn(buttonEl, 'dispatchEvent');
        wrapper.setProps({
          sidebarExpanded: false,
        });

        await wrapper.vm.$nextTick();

        wrapper.vm.handleLabelsCollapsedButtonClick();

        await wrapper.vm.$nextTick();

        expect(buttonEl.dispatchEvent).toHaveBeenCalledWith(
          expect.objectContaining({
            type: 'click',
            bubbles: true,
            cancelable: false,
          }),
        );
      });
    });

    describe('handleUpdateSelectedLabels', () => {
      const updatedLabels = [
        {
          ...mockLabels[0],
          set: false,
        },
      ];

      it('sets `testCaseLabelsSelectInProgress` to true when provided labels param includes any of the additions or removals', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        wrapper.vm.handleUpdateSelectedLabels(updatedLabels);

        expect(wrapper.vm.testCaseLabelsSelectInProgress).toBe(true);
      });

      it('calls `updateTestCase` method with variables `addLabelIds` & `removeLabelIds` and erroMessage when provided labels param includes any of the additions or removals', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        wrapper.vm.handleUpdateSelectedLabels(updatedLabels);

        expect(wrapper.vm.updateTestCase).toHaveBeenCalledWith({
          variables: {
            addLabelIds: [],
            removeLabelIds: [updatedLabels[0].id],
          },
          errorMessage: 'Something went wrong while updating the test case labels.',
        });
      });

      it('emits "test-case-updated" event on component upon promise resolve', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);
        jest.spyOn(wrapper.vm, '$emit');

        return wrapper.vm.handleUpdateSelectedLabels(updatedLabels).then(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('test-case-updated', mockTestCase);
        });
      });

      it('sets `testCaseLabelsSelectInProgress` to false', () => {
        jest.spyOn(wrapper.vm, 'updateTestCase').mockResolvedValue(mockTestCase);

        return wrapper.vm.handleUpdateSelectedLabels(updatedLabels).finally(() => {
          expect(wrapper.vm.testCaseLabelsSelectInProgress).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    it('renders todo button', async () => {
      let todoEl = wrapper.find('[data-testid="todo"]');

      expect(todoEl.exists()).toBe(true);
      expect(todoEl.text()).toContain('To Do');
      expect(todoEl.find(GlButton).exists()).toBe(true);
      expect(todoEl.find(GlButton).text()).toBe('Add a to do');

      wrapper.setProps({
        sidebarExpanded: false,
      });

      await wrapper.vm.$nextTick();

      todoEl = wrapper.find('button');

      expect(todoEl.exists()).toBe(true);
      expect(todoEl.attributes('title')).toBe('Add a to do');
      expect(todoEl.find(GlIcon).exists()).toBe(true);
    });

    it('renders label-select', async () => {
      const { selectedLabels, testCaseLabelsSelectInProgress } = wrapper.vm;
      const { canEditTestCase, labelsFetchPath, labelsManagePath } = mockProvide;
      const labelSelectEl = wrapper.find(LabelsSelect);

      expect(labelSelectEl.exists()).toBe(true);
      expect(labelSelectEl.props()).toMatchObject({
        selectedLabels,
        labelsFetchPath,
        labelsManagePath,
        allowLabelCreate: true,
        allowMultiselect: true,
        variant: 'sidebar',
        allowLabelEdit: canEditTestCase,
        labelsSelectInProgress: testCaseLabelsSelectInProgress,
      });
      expect(labelSelectEl.text()).toBe('None');
    });
  });
});
