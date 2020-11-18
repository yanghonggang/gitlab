import { GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';

import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import { treeItemChevronBtnClassName } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';

import {
  mockQueryResponse,
  mockInitialConfig,
  mockParentItem,
  mockEpic1,
  mockIssue2,
} from '../mock_data';

const { epic } = mockQueryResponse.data.group;

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = ({
  parentItem = mockParentItem,
  epicPageInfo = epic.children.pageInfo,
  issuesPageInfo = epic.issues.pageInfo,
} = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });

  store.dispatch('setEpicPageInfo', {
    parentItem,
    pageInfo: epicPageInfo,
  });

  store.dispatch('setIssuePageInfo', {
    parentItem,
    pageInfo: issuesPageInfo,
  });

  return shallowMount(TreeRoot, {
    localVue,
    store,
    stubs: {
      'tree-item': true,
    },
    propsData: {
      parentItem,
      children,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeRoot', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('mixins', () => {
      describe('TreeDragAndDropMixin', () => {
        const containedDragClassOriginally = document.body.classList.contains('is-dragging');
        const containedNoDropClassOriginally = document.body.classList.contains('no-drop');

        beforeEach(() => {
          document.body.classList.remove('is-dragging');
          document.body.classList.remove('no-drop');
        });

        afterAll(() => {
          // Prevent side-effects of this test.
          document.body.classList.toggle('is-dragging', containedDragClassOriginally);
          document.body.classList.toggle('no-drop', containedNoDropClassOriginally);
        });

        describe('computed', () => {
          describe('treeRootWrapper', () => {
            it('should return Draggable reference when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootWrapper).toBe(Draggable);
            });

            it('should return string "ul" when userSignedIn prop is false', () => {
              wrapper.vm.$store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootWrapper).toBe('ul');
            });
          });

          describe('treeRootOptions', () => {
            it('should return object containing Vue.Draggable config extended from `defaultSortableConfig` when userSignedIn prop is true', () => {
              expect(wrapper.vm.treeRootOptions).toEqual(
                expect.objectContaining({
                  animation: 200,
                  forceFallback: true,
                  fallbackClass: 'is-dragging',
                  fallbackOnBody: false,
                  ghostClass: 'is-ghost',
                  group: 'sortable-container',
                  tag: 'ul',
                  'ghost-class': 'tree-item-drag-active',
                  'data-parent-reference': mockParentItem.reference,
                  'data-parent-id': mockParentItem.id,
                  value: wrapper.vm.children,
                  filter: `.${treeItemChevronBtnClassName}`,
                }),
              );
            });

            it('should return an empty object when userSignedIn prop is false', () => {
              wrapper.vm.$store.dispatch('setInitialConfig', {
                ...mockInitialConfig,
                userSignedIn: false,
              });

              expect(wrapper.vm.treeRootOptions).toEqual(expect.objectContaining({}));
            });
          });
        });

        describe('methods', () => {
          describe('getItemId', () => {
            it('returns value of `id` prop when item is an Epic', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[0])).toBe(mockEpic1.id);
            });

            it('returns value of `epicIssueId` prop when item is an Issue', () => {
              expect(wrapper.vm.getItemId(wrapper.vm.children[2])).toBe(mockIssue2.epicIssueId);
            });
          });

          describe('getTreeReorderMutation', () => {
            it('returns an object containing ID of targetItem', () => {
              const targetItemEpic = wrapper.vm.children[0];
              const targetItemIssue = wrapper.vm.children[2];
              const newIndex = 0;

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemEpic,
                  newIndex,
                }),
              ).toEqual(
                expect.objectContaining({
                  id: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem: targetItemIssue,
                  newIndex,
                }),
              ).toEqual(
                expect.objectContaining({
                  id: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns an object containing `adjacentReferenceId` of children item at provided `newIndex`', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                expect.objectContaining({
                  adjacentReferenceId: mockEpic1.id,
                }),
              );

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                expect.objectContaining({
                  adjacentReferenceId: mockIssue2.epicIssueId,
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param is 0', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 0,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `before` when `newIndex` param is last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: wrapper.vm.children.length - 1,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'before',
                }),
              );
            });

            it('returns object containing `relativePosition` containing `after` when `newIndex` param neither `0` nor last item index', () => {
              const targetItem = wrapper.vm.children[0];

              expect(
                wrapper.vm.getTreeReorderMutation({
                  targetItem,
                  newIndex: 2,
                }),
              ).toEqual(
                expect.objectContaining({
                  relativePosition: 'after',
                }),
              );
            });
          });

          describe('handleDragOnStart', () => {
            it('adds a class `is-dragging` to document body', () => {
              expect(document.body.classList.contains('is-dragging')).toBe(false);

              wrapper.vm.handleDragOnStart();

              expect(document.body.classList.contains('is-dragging')).toBe(true);
            });
          });

          describe('handleDragOnEnd', () => {
            it('removes class `is-dragging` from document body', () => {
              jest.spyOn(wrapper.vm, 'reorderItem').mockImplementation(() => {});
              document.body.classList.add('is-dragging');

              wrapper.vm.handleDragOnEnd({
                oldIndex: 1,
                newIndex: 0,
              });

              expect(document.body.classList.contains('is-dragging')).toBe(false);
            });

            describe('origin parent is destination parent', () => {
              it('does not call `reorderItem` action when newIndex is same as oldIndex', () => {
                jest.spyOn(wrapper.vm, 'reorderItem').mockImplementation(() => {});

                wrapper.vm.handleDragOnEnd({
                  oldIndex: 0,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.element,
                });

                expect(wrapper.vm.reorderItem).not.toHaveBeenCalled();
              });

              it('calls `reorderItem` action when newIndex is different from oldIndex', () => {
                jest.spyOn(wrapper.vm, 'reorderItem').mockImplementation(() => {});

                wrapper.vm.handleDragOnEnd({
                  oldIndex: 1,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.element,
                });

                expect(wrapper.vm.reorderItem).toHaveBeenCalledWith(
                  expect.objectContaining({
                    treeReorderMutation: expect.any(Object),
                    parentItem: wrapper.vm.parentItem,
                    targetItem: wrapper.vm.children[1],
                    oldIndex: 1,
                    newIndex: 0,
                  }),
                );
              });
            });

            describe('origin parent is different than destination parent', () => {
              it('calls `moveItem`', () => {
                jest.spyOn(wrapper.vm, 'moveItem').mockImplementation(() => {});

                wrapper.vm.handleDragOnEnd({
                  oldIndex: 1,
                  newIndex: 0,
                  from: wrapper.element,
                  to: wrapper.find('li:first-child .sub-tree-root'),
                });

                expect(wrapper.vm.moveItem).toHaveBeenCalledWith(
                  expect.objectContaining({
                    oldParentItem: wrapper.vm.parentItem,
                    newParentItem: wrapper.find('li:first-child .sub-tree-root').dataset,
                    targetItem: wrapper.vm.children[1],
                    oldIndex: 1,
                    newIndex: 0,
                  }),
                );
              });
            });
          });
        });
      });
    });

    describe('computed', () => {
      describe('hasMoreChildren', () => {
        it('returns `true` when either `hasMoreEpics` or `hasMoreIssues` is true', () => {
          expect(wrapper.vm.hasMoreChildren).toBe(true);
        });

        it('returns `false` when both `hasMoreEpics` and `hasMoreIssues` is false', () => {
          const wrapperNoMoreChild = createComponent({
            epicPageInfo: {
              hasNextPage: false,
              endCursor: 'abc',
            },
            issuesPageInfo: {
              hasNextPage: false,
              endCursor: 'def',
            },
          });

          expect(wrapperNoMoreChild.vm.hasMoreChildren).toBe(false);

          wrapperNoMoreChild.destroy();
        });
      });
    });

    describe('methods', () => {
      describe('handleShowMoreClick', () => {
        it('sets `fetchInProgress` to true and calls `fetchNextPageItems` action with parentItem as param', () => {
          jest
            .spyOn(wrapper.vm, 'fetchNextPageItems')
            .mockImplementation(() => new Promise(() => {}));

          wrapper.vm.handleShowMoreClick();

          expect(wrapper.vm.fetchInProgress).toBe(true);
          expect(wrapper.vm.fetchNextPageItems).toHaveBeenCalledWith(
            expect.objectContaining({
              parentItem: mockParentItem,
            }),
          );
        });
      });

      describe('onMove', () => {
        it('calls toggleItem action if move event finds epic element', () => {
          jest.spyOn(wrapper.vm, 'toggleItem').mockImplementation(() => {});
          const evt = {
            relatedContext: {
              element: mockParentItem,
            },
          };
          wrapper.vm.onMove(evt);

          expect(wrapper.vm.toggleItem).toHaveBeenCalled();
        });

        it(' does not call toggleItem action if move event does not find epic element', () => {
          jest.spyOn(wrapper.vm, 'toggleItem').mockImplementation(() => {});
          const evt = {
            relatedContext: {
              element: mockIssue2,
            },
          };
          wrapper.vm.onMove(evt);

          expect(wrapper.vm.toggleItem).not.toHaveBeenCalled();
        });
      });
    });

    describe('template', () => {
      it('renders tree item component', () => {
        expect(wrapper.html()).toContain('tree-item-stub');
      });

      it('renders `Show more` link', () => {
        expect(wrapper.find(GlButton).text()).toBe('Show more');
      });

      it('calls `handleShowMoreClick` when `Show more` link is clicked', () => {
        jest.spyOn(wrapper.vm, 'handleShowMoreClick').mockImplementation(() => {});

        wrapper.find(GlButton).vm.$emit('click');

        expect(wrapper.vm.handleShowMoreClick).toHaveBeenCalled();
      });
    });
  });
});
