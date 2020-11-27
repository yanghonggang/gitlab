import { mount } from '@vue/test-utils';
import Vue from 'vue';

import milestoneItemComponent from 'ee/roadmap/components/milestone_item.vue';

import { PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockMilestone2 } from 'ee_jest/roadmap/mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  milestone = mockMilestone2,
  timeframe = mockTimeframeMonths,
  timeframeItem = mockTimeframeMonths[0],
}) => {
  const Component = Vue.extend(milestoneItemComponent);

  return mount(Component, {
    propsData: {
      presetType,
      milestone,
      timeframe,
      timeframeItem,
    },
    stubs: { GlPopover: true },
  });
};

describe('MilestoneItemComponent', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe('startDateValues', () => {
      it('returns object containing date parts from milestone.startDate', () => {
        expect(wrapper.vm.startDateValues).toMatchObject({
          day: mockMilestone2.startDate.getDay(),
          date: mockMilestone2.startDate.getDate(),
          month: mockMilestone2.startDate.getMonth(),
          year: mockMilestone2.startDate.getFullYear(),
          time: mockMilestone2.startDate.getTime(),
        });
      });
    });

    describe('endDateValues', () => {
      it('returns object containing date parts from milestone.endDate', () => {
        expect(wrapper.vm.endDateValues).toMatchObject({
          day: mockMilestone2.endDate.getDay(),
          date: mockMilestone2.endDate.getDate(),
          month: mockMilestone2.endDate.getMonth(),
          year: mockMilestone2.endDate.getFullYear(),
          time: mockMilestone2.endDate.getTime(),
        });
      });
    });

    it('returns Milestone.startDate when start date is within range', () => {
      wrapper = createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.startDate).toBe(mockMilestone2.startDate);
    });

    it('returns Milestone.originalStartDate when start date is out of range', () => {
      const mockStartDate = new Date(2018, 0, 1);
      const mockMilestoneItem = {
        ...mockMilestone2,
        startDateOutOfRange: true,
        originalStartDate: mockStartDate,
      };
      wrapper = createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.startDate).toBe(mockStartDate);
    });
  });

  describe('endDate', () => {
    it('returns Milestone.endDate when end date is within range', () => {
      wrapper = createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.endDate).toBe(mockMilestone2.endDate);
    });

    it('returns Milestone.originalEndDate when end date is out of range', () => {
      const mockEndDate = new Date(2018, 0, 1);
      const mockMilestoneItem = {
        ...mockMilestone2,
        endDateOutOfRange: true,
        originalEndDate: mockEndDate,
      };
      wrapper = createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.endDate).toBe(mockEndDate);
    });
  });

  describe('timeframeString', () => {
    it('returns timeframe string correctly when both start and end dates are defined', () => {
      wrapper = createComponent({ milestone: mockMilestone2 });

      expect(wrapper.vm.timeframeString(mockMilestone2)).toBe('Nov 10, 2017 – Jul 2, 2018');
    });

    it('returns timeframe string correctly when only start date is defined', () => {
      const mockMilestoneItem = { ...mockMilestone2, endDateUndefined: true };
      wrapper = createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('Nov 10, 2017 – No end date');
    });

    it('returns timeframe string correctly when only end date is defined', () => {
      const mockMilestoneItem = { ...mockMilestone2, startDateUndefined: true };
      wrapper = createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('No start date – Jul 2, 2018');
    });

    it('returns timeframe string with hidden year for start date when both start and end dates are from same year', () => {
      const mockMilestoneItem = {
        ...mockMilestone2,
        startDate: new Date(2018, 0, 1),
        endDate: new Date(2018, 3, 1),
      };
      wrapper = createComponent({ milestone: mockMilestoneItem });

      expect(wrapper.vm.timeframeString(mockMilestoneItem)).toBe('Jan 1 – Apr 1, 2018');
    });
  });

  describe('template', () => {
    it('renders component container element class `timeline-bar-wrapper`', () => {
      expect(wrapper.vm.$el.classList.contains('timeline-bar-wrapper')).toBeTruthy();
    });

    it('renders component element class `milestone-item-details`', () => {
      expect(wrapper.vm.$el.querySelector('.milestone-item-details')).not.toBeNull();
    });

    it('renders Milestone item link element with class `milestone-url`', () => {
      expect(wrapper.vm.$el.querySelector('.milestone-url')).not.toBeNull();
    });

    it('renders Milestone timeline bar element with class `timeline-bar`', () => {
      expect(wrapper.vm.$el.querySelector('.timeline-bar')).not.toBeNull();
    });

    it('renders Milestone title element with class `milestone-item-title`', () => {
      expect(wrapper.vm.$el.querySelector('.milestone-item-title')).not.toBeNull();
    });
  });
});
