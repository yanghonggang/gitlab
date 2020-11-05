/*
    To avoid duplicating tests in time_tracker.spec,
    this spec only contains a simple test to check rendering.

    A detailed feature spec is used to test time tracking feature
    in swimlanes sidebar.
*/

import { shallowMount } from '@vue/test-utils';
import BoardSidebarTimeTracker from 'ee/boards/components/sidebar/board_sidebar_time_tracker.vue';
import IssuableTimeTracker from '~/sidebar/components/time_tracking/time_tracker.vue';
import { createStore } from '~/boards/stores';

describe('BoardSidebarTimeTracker', () => {
  let wrapper;
  let store;

  const createComponent = options => {
    wrapper = shallowMount(BoardSidebarTimeTracker, {
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.state.issues = {
      '1': {
        timeEstimate: 3600,
        totalTimeSpent: 1800,
        humanTimeEstimate: '1h',
        humanTotalTimeSpent: '30min',
      },
    };
    store.state.activeId = '1';
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it.each([[true], [false]])(
    'renders IssuableTimeTracker with correct spent and estimated time (timeTrackingLimitToHours=%s)',
    timeTrackingLimitToHours => {
      createComponent({ provide: { timeTrackingLimitToHours } });

      expect(wrapper.find(IssuableTimeTracker).props()).toEqual({
        timeEstimate: 3600,
        timeSpent: 1800,
        humanTimeEstimate: '1h',
        humanTimeSpent: '30min',
        limitToHours: timeTrackingLimitToHours,
        showCollapsed: false,
      });
    },
  );
});
