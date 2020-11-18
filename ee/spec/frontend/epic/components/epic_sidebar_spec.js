import { shallowMount } from '@vue/test-utils';

import EpicSidebar from 'ee/epic/components/epic_sidebar.vue';
import { dateTypes } from 'ee/epic/constants';
import createStore from 'ee/epic/store';

import epicUtils from 'ee/epic/utils/epic_utils';

import { parsePikadayDate } from '~/lib/utils/datetime_utility';

import { mockEpicMeta, mockEpicData, mockAncestors } from '../mock_data';

const createComponent = ({ methods } = {}) => {
  const store = createStore();
  store.dispatch('setEpicMeta', mockEpicMeta);
  store.dispatch('setEpicData', mockEpicData);
  store.state.ancestors = mockAncestors;

  return shallowMount(EpicSidebar, {
    store,
    methods,
  });
};

describe('EpicSidebarComponent', () => {
  const originalUserId = gon.current_user_id;
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('getDateFromMilestonesTooltip', () => {
      it('calls `epicUtils.getDateFromMilestonesTooltip` with `dateType` param', () => {
        jest.spyOn(epicUtils, 'getDateFromMilestonesTooltip');

        wrapper.vm.getDateFromMilestonesTooltip(dateTypes.start);

        expect(epicUtils.getDateFromMilestonesTooltip).toHaveBeenCalledWith(
          expect.objectContaining({
            dateType: dateTypes.start,
          }),
        );
      });
    });

    describe('changeStartDateType', () => {
      it('calls `toggleStartDateType` on component with `dateTypeIsFixed` param', () => {
        jest.spyOn(wrapper.vm, 'toggleStartDateType');

        wrapper.vm.changeStartDateType(true, true);

        expect(wrapper.vm.toggleStartDateType).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.changeStartDateType(true, false);

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-06-01',
          }),
        );
      });
    });

    describe('saveStartDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.saveStartDate('2018-1-1');

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-1-1',
          }),
        );
      });
    });

    describe('changeDueDateType', () => {
      it('calls `toggleDueDateType` on component with `dateTypeIsFixed` param', () => {
        jest.spyOn(wrapper.vm, 'toggleDueDateType');

        wrapper.vm.changeDueDateType(true, true);

        expect(wrapper.vm.toggleDueDateType).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.changeDueDateType(true, false);

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-08-01',
          }),
        );
      });
    });

    describe('saveDueDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        jest.spyOn(wrapper.vm, 'saveDate');

        wrapper.vm.saveDueDate('2018-1-1');

        expect(wrapper.vm.saveDate).toHaveBeenCalledWith(
          expect.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-1-1',
          }),
        );
      });
    });
  });

  describe('template', () => {
    beforeAll(() => {
      gon.current_user_id = 1;
    });

    afterAll(() => {
      gon.current_user_id = originalUserId;
    });

    it('renders component container element with classes `right-sidebar-expanded`, `right-sidebar` & `epic-sidebar`', async () => {
      wrapper.vm.$store.dispatch('toggleSidebarFlag', false);

      await wrapper.vm.$nextTick();

      expect(wrapper.classes()).toContain('right-sidebar-expanded');
      expect(wrapper.classes()).toContain('right-sidebar');
      expect(wrapper.classes()).toContain('epic-sidebar');
    });

    it('renders header container element with classes `issuable-sidebar` & `js-issuable-update`', () => {
      expect(wrapper.find('.issuable-sidebar.js-issuable-update').exists()).toBe(true);
    });

    it('renders Todo toggle button element when sidebar is collapsed and user is signed in', async () => {
      wrapper.vm.$store.dispatch('toggleSidebarFlag', true);

      await wrapper.vm.$nextTick();

      expect(wrapper.find('[data-testid="todo"]').exists()).toBe(true);
    });

    it('renders Start date & Due date elements when sidebar is expanded', async () => {
      wrapper.vm.$store.dispatch('toggleSidebarFlag', false);

      await wrapper.vm.$nextTick();

      const startDateEl = wrapper.find('[data-testid="start-date"]');
      const dueDateEl = wrapper.find('[data-testid="due-date"]');

      expect(startDateEl.exists()).toBe(true);
      expect(startDateEl.props()).toMatchObject({
        label: 'Start date',
        dateFixed: parsePikadayDate(mockEpicMeta.startDateFixed),
      });

      expect(dueDateEl.exists()).toBe(true);
      expect(dueDateEl.props()).toMatchObject({
        label: 'Due date',
        dateFixed: parsePikadayDate(mockEpicMeta.dueDateFixed),
      });
    });

    it('renders labels select element', () => {
      expect(wrapper.find('[data-testid="labels-select"]').exists()).toBe(true);
    });

    describe('when sub-epics feature is available', () => {
      it('renders ancestors list', async () => {
        wrapper.vm.$store.dispatch('toggleSidebarFlag', false);
        wrapper.vm.$store.dispatch('setEpicMeta', {
          ...mockEpicMeta,
          allowSubEpics: false,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.find('.block.ancestors').exists()).toBe(false);
      });
    });

    describe('when sub-epics feature is not available', () => {
      it('does not render ancestors list', async () => {
        wrapper.vm.$store.dispatch('toggleSidebarFlag', false);

        await wrapper.vm.$nextTick();

        const ancestorsEl = wrapper.find('[data-testid="ancestors"]');

        expect(ancestorsEl.exists()).toBe(true);
        expect(ancestorsEl.props('ancestors')).toEqual([...mockAncestors].reverse());
      });
    });

    it('renders participants list element', () => {
      expect(wrapper.find('.block.participants').exists()).toBe(true);
    });

    it('renders subscription toggle element', () => {
      expect(wrapper.find('[data-testid="subscribe"]').exists()).toBe(true);
    });
  });

  describe('mounted', () => {
    it('makes request to get epic details', () => {
      const methodSpies = {
        fetchEpicDetails: jest.fn(),
      };

      const wrapperWithMethod = createComponent({
        methods: methodSpies,
      });

      expect(methodSpies.fetchEpicDetails).toHaveBeenCalled();

      wrapperWithMethod.destroy();
    });
  });
});
