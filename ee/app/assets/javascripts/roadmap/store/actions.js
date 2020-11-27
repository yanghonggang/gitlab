import { deprecatedCreateFlash as flash } from '~/flash';
import { s__ } from '~/locale';

import * as epicUtils from '../utils/epic_utils';
import * as roadmapItemUtils from '../utils/roadmap_item_utils';
import {
  getEpicsTimeframeRange,
  sortEpics,
  extendTimeframeForPreset,
} from '../utils/roadmap_utils';

import { EXTEND_AS } from '../constants';

import groupEpics from '../queries/groupEpics.query.graphql';
import epicChildEpics from '../queries/epicChildEpics.query.graphql';
import groupMilestones from '../queries/groupMilestones.query.graphql';

import * as types from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

const fetchGroupEpics = (
  { epicIid, fullPath, epicsState, sortedBy, presetType, filterParams, timeframe },
  defaultTimeframe,
) => {
  let query;
  let variables = {
    fullPath,
    state: epicsState,
    sort: sortedBy,
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
  };

  // When epicIid is present,
  // Roadmap is being accessed from within an Epic,
  // and then we don't need to pass `filterParams`.
  if (epicIid) {
    query = epicChildEpics;
    variables.iid = epicIid;
  } else {
    query = groupEpics;
    variables = {
      ...variables,
      ...filterParams,
    };
  }

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const edges = epicIid
        ? data?.group?.epic?.children?.edges || []
        : data?.group?.epics?.edges || [];

      return epicUtils.extractGroupEpics(edges);
    });
};

export const fetchChildrenEpics = (state, { parentItem }) => {
  const { iid, group } = parentItem;
  const { filterParams, epicsState } = state;

  return epicUtils.gqClient
    .query({
      query: epicChildEpics,
      variables: { iid, fullPath: group?.fullPath, state: epicsState, ...filterParams },
    })
    .then(({ data }) => {
      const edges = data?.group?.epic?.children?.edges || [];
      return epicUtils.extractGroupEpics(edges);
    });
};

export const receiveEpicsSuccess = (
  { commit, dispatch, state, getters },
  { rawEpics, newEpic, timeframeExtended },
) => {
  const epicIds = [];
  const epics = rawEpics.reduce((filteredEpics, epic) => {
    const formattedEpic = roadmapItemUtils.formatRoadmapItemDetails(
      epic,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    );

    formattedEpic.isChildEpic = false;

    // Exclude any Epic that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedEpic.startDate.getTime() <= formattedEpic.endDate.getTime() &&
      state.epicIds.indexOf(formattedEpic.id) < 0
    ) {
      Object.assign(formattedEpic, {
        newEpic,
      });
      filteredEpics.push(formattedEpic);
      epicIds.push(formattedEpic.id);
    }
    return filteredEpics;
  }, []);

  commit(types.UPDATE_EPIC_IDS, epicIds);
  dispatch('initItemChildrenFlags', { epics });

  if (timeframeExtended) {
    const updatedEpics = state.epics.concat(epics);
    sortEpics(updatedEpics, state.sortedBy);
    commit(types.RECEIVE_EPICS_FOR_TIMEFRAME_SUCCESS, updatedEpics);
  } else {
    commit(types.RECEIVE_EPICS_SUCCESS, epics);
  }
};
export const receiveEpicsFailure = ({ commit }) => {
  commit(types.RECEIVE_EPICS_FAILURE);
  flash(s__('GroupRoadmap|Something went wrong while fetching epics'));
};

export const requestChildrenEpics = ({ commit }, { parentItemId }) => {
  commit(types.REQUEST_CHILDREN_EPICS, { parentItemId });
};
export const receiveChildrenSuccess = (
  { commit, dispatch, getters },
  { parentItemId, rawChildren },
) => {
  const children = rawChildren.reduce((filteredChildren, epic) => {
    const formattedChild = roadmapItemUtils.formatRoadmapItemDetails(
      epic,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    );

    formattedChild.isChildEpic = true;

    // Exclude any Epic that has invalid dates
    if (formattedChild.startDate.getTime() <= formattedChild.endDate.getTime()) {
      filteredChildren.push(formattedChild);
    }
    return filteredChildren;
  }, []);
  dispatch('expandEpic', {
    parentItemId,
  });
  dispatch('initItemChildrenFlags', { epics: children });
  commit(types.RECEIVE_CHILDREN_SUCCESS, { parentItemId, children });
};

export const fetchEpics = ({ state, commit, dispatch }) => {
  commit(types.REQUEST_EPICS);

  fetchGroupEpics(state)
    .then(rawEpics => {
      dispatch('receiveEpicsSuccess', { rawEpics });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

export const fetchEpicsForTimeframe = ({ state, commit, dispatch }, { timeframe }) => {
  commit(types.REQUEST_EPICS_FOR_TIMEFRAME);

  return fetchGroupEpics(state, timeframe)
    .then(rawEpics => {
      dispatch('receiveEpicsSuccess', {
        rawEpics,
        newEpic: true,
        timeframeExtended: true,
      });
    })
    .catch(() => dispatch('receiveEpicsFailure'));
};

/**
 * Adds more EpicItemTimeline cells to the start or end of the roadmap.
 *
 * @param extendAs An EXTEND_AS enum value
 */
export const extendTimeframe = ({ commit, state, getters }, { extendAs }) => {
  const isExtendTypePrepend = extendAs === EXTEND_AS.PREPEND;

  const timeframeToExtend = extendTimeframeForPreset({
    extendAs,
    presetType: state.presetType,
    initialDate: isExtendTypePrepend ? getters.timeframeStartDate : getters.timeframeEndDate,
  });

  if (isExtendTypePrepend) {
    commit(types.PREPEND_TIMEFRAME, timeframeToExtend);
  } else {
    commit(types.APPEND_TIMEFRAME, timeframeToExtend);
  }
};

export const initItemChildrenFlags = ({ commit }, data) =>
  commit(types.INIT_EPIC_CHILDREN_FLAGS, data);

export const expandEpic = ({ commit }, { parentItemId }) =>
  commit(types.EXPAND_EPIC, { parentItemId });
export const collapseEpic = ({ commit }, { parentItemId }) =>
  commit(types.COLLAPSE_EPIC, { parentItemId });

export const toggleEpic = ({ state, dispatch }, { parentItem }) => {
  const parentItemId = parentItem.id;
  if (!state.childrenFlags[parentItemId].itemExpanded) {
    if (!state.childrenEpics[parentItemId]) {
      dispatch('requestChildrenEpics', { parentItemId });
      fetchChildrenEpics(state, { parentItem })
        .then(rawChildren => {
          dispatch('receiveChildrenSuccess', {
            parentItemId,
            rawChildren,
          });
        })
        .catch(() => dispatch('receiveEpicsFailure'));
    } else {
      dispatch('expandEpic', {
        parentItemId,
      });
    }
  } else {
    dispatch('collapseEpic', {
      parentItemId,
    });
  }
};

/**
 * For epics that have no start or end date, this function updates their start and end dates
 * so that the epic bars get longer to appear infinitely scrolling.
 */
export const refreshEpicDates = ({ commit, state, getters }) => {
  const epics = state.epics.map(epic => {
    // Update child epic dates too
    if (epic.children?.edges?.length > 0) {
      epic.children.edges.map(childEpic =>
        roadmapItemUtils.processRoadmapItemDates(
          childEpic,
          getters.timeframeStartDate,
          getters.timeframeEndDate,
        ),
      );
    }
    return roadmapItemUtils.processRoadmapItemDates(
      epic,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    );
  });

  commit(types.SET_EPICS, epics);
};

export const fetchGroupMilestones = (
  { fullPath, presetType, filterParams, timeframe },
  defaultTimeframe,
) => {
  const query = groupMilestones;
  const variables = {
    fullPath,
    state: 'active',
    ...getEpicsTimeframeRange({
      presetType,
      timeframe: defaultTimeframe || timeframe,
    }),
    includeDescendants: true,
    ...filterParams,
  };

  return epicUtils.gqClient
    .query({
      query,
      variables,
    })
    .then(({ data }) => {
      const { group } = data;

      const edges = (group.milestones && group.milestones.edges) || [];

      return roadmapItemUtils.extractGroupMilestones(edges);
    });
};

export const requestMilestones = ({ commit }) => commit(types.REQUEST_MILESTONES);

export const fetchMilestones = ({ state, dispatch }) => {
  dispatch('requestMilestones');

  return fetchGroupMilestones(state)
    .then(rawMilestones => {
      dispatch('receiveMilestonesSuccess', { rawMilestones });
    })
    .catch(() => dispatch('receiveMilestonesFailure'));
};

export const receiveMilestonesSuccess = (
  { commit, state, getters },
  { rawMilestones, newMilestone }, // timeframeExtended
) => {
  const milestoneIds = [];
  const milestones = rawMilestones.reduce((filteredMilestones, milestone) => {
    const formattedMilestone = roadmapItemUtils.formatRoadmapItemDetails(
      milestone,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    );
    // Exclude any Milestone that has invalid dates
    // or is already present in Roadmap timeline
    if (
      formattedMilestone.startDate.getTime() <= formattedMilestone.endDate.getTime() &&
      state.milestoneIds.indexOf(formattedMilestone.id) < 0
    ) {
      Object.assign(formattedMilestone, {
        newMilestone,
      });
      filteredMilestones.push(formattedMilestone);
      milestoneIds.push(formattedMilestone.id);
    }
    return filteredMilestones;
  }, []);

  commit(types.UPDATE_MILESTONE_IDS, milestoneIds);
  commit(types.RECEIVE_MILESTONES_SUCCESS, milestones);
};

export const receiveMilestonesFailure = ({ commit }) => {
  commit(types.RECEIVE_MILESTONES_FAILURE);
  flash(s__('GroupRoadmap|Something went wrong while fetching milestones'));
};

export const refreshMilestoneDates = ({ commit, state, getters }) => {
  const milestones = state.milestones.map(milestone =>
    roadmapItemUtils.processRoadmapItemDates(
      milestone,
      getters.timeframeStartDate,
      getters.timeframeEndDate,
    ),
  );

  commit(types.SET_MILESTONES, milestones);
};

export const setBufferSize = ({ commit }, bufferSize) => commit(types.SET_BUFFER_SIZE, bufferSize);

export const setEpicsState = ({ commit }, epicsState) => commit(types.SET_EPICS_STATE, epicsState);

export const setFilterParams = ({ commit }, filterParams) =>
  commit(types.SET_FILTER_PARAMS, filterParams);

export const setSortedBy = ({ commit }, sortedBy) => commit(types.SET_SORTED_BY, sortedBy);
