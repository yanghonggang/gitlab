import { GlIcon, GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import MilestoneTimeline from 'ee/roadmap/components/milestone_timeline.vue';
import milestonesListSectionComponent from 'ee/roadmap/components/milestones_list_section.vue';
import {
  PRESET_TYPES,
  EPIC_DETAILS_CELL_WIDTH,
  TIMELINE_CELL_MIN_WIDTH,
} from 'ee/roadmap/constants';
import createStore from 'ee/roadmap/store';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';
import { mockTimeframeInitialDate, mockGroupId, rawMilestones } from 'ee_jest/roadmap/mock_data';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

const initializeStore = mockTimeframeMonths => {
  const store = createStore();
  store.dispatch('setInitialData', {
    currentGroupId: mockGroupId,
    presetType: PRESET_TYPES.MONTHS,
    timeframe: mockTimeframeMonths,
  });
  store.dispatch('receiveMilestonesSuccess', { rawMilestones });
  return store;
};

describe('MilestonesListSectionComponent', () => {
  let wrapper;
  let store;

  const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);
  const findMilestoneCount = () => wrapper.find('[data-testid="count"]');
  const findMilestoneCountTooltip = () => getBinding(findMilestoneCount().element, 'gl-tooltip');
  const findExpandButtonContainer = () => wrapper.find('[data-testid="expandButton"]');
  const findExpandButtonData = () => {
    const container = findExpandButtonContainer();
    return {
      icon: container.find(GlIcon).attributes('name'),
      iconLabel: container.find(GlButton).attributes('aria-label'),
      tooltip: getBinding(container.element, 'gl-tooltip').value.title,
    };
  };

  const createWrapper = (props = {}) => {
    const localVue = createLocalVue();
    wrapper = shallowMount(milestonesListSectionComponent, {
      localVue,
      store,
      stubs: {
        MilestoneTimeline: false,
      },
      propsData: {
        milestones: store.state.milestones,
        timeframe: mockTimeframeMonths,
        currentGroupId: mockGroupId,
        presetType: PRESET_TYPES.MONTHS,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    store = initializeStore(mockTimeframeMonths);
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(wrapper.vm.offsetLeft).toBe(0);
      expect(wrapper.vm.roadmapShellEl).toBeDefined();
      expect(wrapper.vm.milestonesExpanded).toBe(true);
    });
  });

  describe('computed', () => {
    describe('sectionContainerStyles', () => {
      it('returns style string for container element based on sectionShellWidth', () => {
        expect(wrapper.vm.sectionContainerStyles.width).toBe(
          `${EPIC_DETAILS_CELL_WIDTH + TIMELINE_CELL_MIN_WIDTH * wrapper.vm.timeframe.length}px`,
        );
      });
    });

    describe('shadowCellStyles', () => {
      it('returns computed style object based on `offsetLeft` prop value', () => {
        expect(wrapper.vm.shadowCellStyles.left).toBe('0px');
      });
    });
  });

  describe('methods', () => {
    describe('initMounted', () => {
      it('sets value of `roadmapShellEl` with root component element', () => {
        expect(wrapper.vm.roadmapShellEl instanceof HTMLElement).toBe(true);
      });
    });

    describe('handleEpicsListScroll', () => {
      it('toggles value of `showBottomShadow` based on provided `scrollTop`, `clientHeight` & `scrollHeight`', () => {
        wrapper.vm.handleEpicsListScroll({
          scrollTop: 5,
          clientHeight: 5,
          scrollHeight: 15,
        });

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(wrapper.vm.showBottomShadow).toBe(true);

        wrapper.vm.handleEpicsListScroll({
          scrollTop: 15,
          clientHeight: 5,
          scrollHeight: 15,
        });

        // Math.ceil(scrollTop) + clientHeight < scrollHeight
        expect(wrapper.vm.showBottomShadow).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders component container element with class `milestones-list-section`', () => {
      expect(wrapper.vm.$el.classList.contains('milestones-list-section')).toBe(true);
    });

    it('renders element with class `milestones-list-title`', () => {
      wrapper.vm.setBufferSize(50);

      expect(wrapper.find('.milestones-list-title').exists()).toBe(true);
    });

    it('renders element with class `milestones-list-items` containing MilestoneTimeline component', () => {
      const listItems = wrapper.find('.milestones-list-items');

      expect(listItems.exists()).toBe(true);
      expect(listItems.find(MilestoneTimeline).exists()).toBe(true);
    });

    it('renders bottom shadow element when `showBottomShadow` prop is true', () => {
      wrapper.setData({
        showBottomShadow: true,
      });

      expect(wrapper.find('.scroll-bottom-shadow').exists()).toBe(true);
    });

    it('show the correct count of milestones ', () => {
      expect(findMilestoneCount().text()).toBe('2');
    });

    it('has a tooltip with the correct count of milestones', () => {
      expect(findMilestoneCountTooltip().value).toBe('2 milestones');
    });

    describe('milestone expand/collapse button', () => {
      it('is rendered', () => {
        expect(findExpandButtonData()).toEqual({
          icon: 'chevron-down',
          iconLabel: 'Collapse milestones',
          tooltip: 'Collapse',
        });
      });
    });
  });

  describe('when the milestone list is expanded', () => {
    beforeEach(() => {
      findExpandButtonContainer()
        .find(GlButton)
        .vm.$emit('click');

      return wrapper.vm.$nextTick();
    });

    it('shows "chevron-right" icon when the milestone toggle button is clicked', () => {
      expect(findExpandButtonData()).toEqual({
        icon: 'chevron-right',
        iconLabel: 'Expand milestones',
        tooltip: 'Expand',
      });
    });
  });
});
