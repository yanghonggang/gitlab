import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EpicItemDetails from 'ee/roadmap/components/epic_item_details.vue';
import eventHub from 'ee/roadmap/event_hub';
import createStore from 'ee/roadmap/store';
import {
  mockGroupId,
  mockFormattedEpic,
  mockFormattedChildEpic2,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

describe('EpicItemDetails', () => {
  let wrapper;
  let store;

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(EpicItemDetails, {
      store,
      propsData: {
        epic: mockFormattedEpic,
        currentGroupId: mockGroupId,
        timeframeString: 'Jul 10, 2017 – Jun 2, 2018',
        childLevel: 0,
        childrenFlags: { '41': { itemExpanded: false } },
        hasFiltersApplied: false,
        isChildrenEmpty: false,
        ...props,
      },
    });
  };

  const getTitle = () => wrapper.find('.epic-title');

  const getGroupName = () => wrapper.find('.epic-group');

  const getChildMarginClassName = () => wrapper.vm.childMarginClassname;

  const getExpandIconButton = () => wrapper.find(GlButton);

  const getExpandIconTooltip = () => wrapper.find({ ref: 'expandIconTooltip' });

  const getChildEpicsCount = () => wrapper.find({ ref: 'childEpicsCount' });

  const getChildEpicsCountTooltip = () => wrapper.find({ ref: 'childEpicsCountTooltip' });

  const getExpandButtonData = () => ({
    icon: wrapper.find(GlIcon).attributes('name'),
    iconLabel: getExpandIconButton().attributes('aria-label'),
    tooltip: getExpandIconTooltip().text(),
  });

  const getEpicTitleData = () => ({
    title: getTitle().text(),
    link: getTitle().attributes('href'),
  });

  const getEpicGroupNameData = () => ({
    groupName: getGroupName().text(),
    title: getGroupName().attributes('title'),
  });

  const createMockEpic = epic => ({
    ...mockFormattedEpic,
    ...epic,
  });

  describe('epic title', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('is displayed with a link to the epic', () => {
      expect(getEpicTitleData()).toEqual({
        title: mockFormattedEpic.title,
        link: mockFormattedEpic.webUrl,
      });
    });
  });

  describe('epic group name', () => {
    const epic = {
      id: '41',
      ...mockFormattedEpic,
      groupId: 1,
      groupName: 'Bar',
      groupFullName: 'Foo / Bar',
      descendantCounts: {
        closedIssues: 3,
        openedIssues: 2,
      },
    };

    describe('when the epic group ID is different from the current group ID', () => {
      it('is displayed and set to the title attribute', () => {
        createWrapper({ epic, currentGroupId: 2 });
        expect(getEpicGroupNameData()).toEqual({
          groupName: epic.groupName,
          title: epic.groupFullName,
        });
      });
    });

    describe('when the epic group ID is the same as the current group ID', () => {
      it('is hidden', () => {
        createWrapper({ epic, currentGroupId: 1 });
        expect(getGroupName().exists()).toBe(false);
      });
    });
  });

  describe('timeframe', () => {
    it('is displayed', () => {
      createWrapper();
      const timeframe = wrapper.find('.epic-timeframe');

      expect(timeframe.text()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });

  describe('childMarginClassname', () => {
    it('childMarginClassname returns class for level 1 child is childLevel is 1', () => {
      createWrapper({ childLevel: 1 });
      expect(getChildMarginClassName()).toEqual('ml-4');
    });

    it('childMarginClassname returns class for level 2 child is childLevel is 2', () => {
      createWrapper({ childLevel: 2 });
      expect(getChildMarginClassName()).toEqual('ml-6');
    });
  });

  describe('epic', () => {
    beforeEach(() => {
      store.state.allowSubEpics = true;
    });

    describe('expand icon', () => {
      it('is hidden when it is child epic', () => {
        const epic = createMockEpic({
          isChildEpic: true,
        });
        createWrapper({ epic });
        expect(getExpandIconButton().classes()).toContain('invisible');
      });

      describe('when epic has no child epics', () => {
        beforeEach(() => {
          const epic = createMockEpic({
            hasChildren: false,
            descendantCounts: {
              openedEpics: 0,
              closedEpics: 0,
            },
          });
          createWrapper({ epic });
        });
        it('is hidden', () => {
          expect(getExpandIconButton().classes()).toContain('invisible');
        });
        describe('child epics count', () => {
          it('shows the count as 0', () => {
            expect(getChildEpicsCount().text()).toBe('0');
          });
        });
      });

      describe('when epic has child epics', () => {
        let epic;
        beforeEach(() => {
          epic = createMockEpic({
            id: 41,
            hasChildren: true,
            children: {
              edges: [mockFormattedChildEpic1],
            },
            descendantCounts: {
              openedEpics: 0,
              closedEpics: 1,
            },
          });
          createWrapper({ epic });
        });

        it('is shown', () => {
          expect(getExpandIconButton().classes()).not.toContain('invisible');
        });

        it('emits toggleIsEpicExpanded event when clicked', () => {
          jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
          getExpandIconButton().vm.$emit('click');
          expect(eventHub.$emit).toHaveBeenCalledWith('toggleIsEpicExpanded', epic);
        });

        describe('when child epics are expanded', () => {
          const childrenFlags = {
            '41': { itemExpanded: true },
          };

          beforeEach(() => {
            createWrapper({ epic, childrenFlags });
          });

          it('shows collapse button', () => {
            expect(getExpandButtonData()).toEqual({
              icon: 'chevron-down',
              iconLabel: 'Collapse',
              tooltip: 'Collapse',
            });
          });

          describe('when filters are applied', () => {
            beforeEach(() => {
              createWrapper({
                epic,
                childrenFlags,
                hasFiltersApplied: true,
                isChildrenEmpty: true,
              });
            });

            it('shows child epics match filters button', () => {
              expect(getExpandButtonData()).toEqual({
                icon: 'information-o',
                iconLabel: 'No child epics match applied filters',
                tooltip: 'No child epics match applied filters',
              });
            });
          });
        });

        describe('when child epics are not expanded', () => {
          beforeEach(() => {
            const childrenFlags = {
              '41': { itemExpanded: false },
            };
            createWrapper({
              epic,
              childrenFlags,
            });
          });

          it('shows expand button', () => {
            expect(getExpandButtonData()).toEqual({
              icon: 'chevron-right',
              iconLabel: 'Expand',
              tooltip: 'Expand',
            });
          });
        });

        describe('child epics count', () => {
          it('has a tooltip with the count', () => {
            createWrapper({ epic });
            expect(getChildEpicsCountTooltip().text()).toBe('1 child epic');
          });

          it('has a tooltip with the count and explanation if search is being performed', () => {
            createWrapper({ epic, hasFiltersApplied: true });
            expect(getChildEpicsCountTooltip().text()).toBe(
              '1 child epic Some child epics may be hidden due to applied filters',
            );
          });

          it('does not render if the user license does not support child epics', () => {
            store.state.allowSubEpics = false;
            createWrapper({ epic });
            expect(getChildEpicsCount().exists()).toBe(false);
          });

          it('shows the correct count of child epics', () => {
            epic = createMockEpic({
              children: {
                edges: [mockFormattedChildEpic1, mockFormattedChildEpic2],
              },
              descendantCounts: {
                openedEpics: 0,
                closedEpics: 2,
              },
            });
            createWrapper({ epic });
            expect(getChildEpicsCount().text()).toBe('2');
          });
        });
      });
    });
  });
});
