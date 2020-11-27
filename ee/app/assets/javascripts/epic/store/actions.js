import epicDetailsQuery from 'shared_queries/epic/epic_details.query.graphql';
import { deprecatedCreateFlash as flash } from '~/flash';
import { __, s__, sprintf } from '~/locale';

import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';

import epicUtils from '../utils/epic_utils';
import { statusType, statusEvent, dateTypes } from '../constants';

import epicSetSubscription from '../queries/epicSetSubscription.mutation.graphql';
import updateEpic from '../queries/updateEpic.mutation.graphql';

import * as types from './mutation_types';

export const setEpicMeta = ({ commit }, meta) => commit(types.SET_EPIC_META, meta);

export const setEpicData = ({ commit }, data) => commit(types.SET_EPIC_DATA, data);

export const fetchEpicDetails = ({ state, dispatch }) => {
  const variables = {
    fullPath: state.fullPath,
    iid: state.epicIid,
  };

  epicUtils.gqClient
    .query({
      query: epicDetailsQuery,
      variables,
    })
    .then(({ data }) => {
      const participants = data.group.epic.participants.edges.map(participant => ({
        name: participant.node.name,
        avatar_url: participant.node.avatarUrl,
        web_url: participant.node.webUrl,
      }));

      dispatch('setEpicData', { participants });
    })
    .catch(() => dispatch('requestEpicParticipantsFailure'));
};

export const requestEpicParticipantsFailure = () => {
  flash(__('There was an error getting the epic participants.'));
};

export const requestEpicStatusChange = ({ commit }) => commit(types.REQUEST_EPIC_STATUS_CHANGE);

export const requestEpicStatusChangeSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS, data);

export const requestEpicStatusChangeFailure = ({ commit }) => {
  commit(types.REQUEST_EPIC_STATUS_CHANGE_FAILURE);
  flash(__('Unable to update this epic at this time.'));
};

export const triggerIssuableEvent = (_, { isEpicOpen }) => {
  // Ensure that status change is reflected across the page.
  // As `Close`/`Reopen` button is also present under
  // comment form (part of Notes app) We've wrapped
  // call to `$(document).trigger` within `triggerDocumentEvent`
  // for ease of testing
  epicUtils.triggerDocumentEvent('issuable_vue_app:change', isEpicOpen);
  epicUtils.triggerDocumentEvent('issuable:change', isEpicOpen);
};

export const toggleEpicStatus = ({ state, dispatch }, isEpicOpen) => {
  dispatch('requestEpicStatusChange');

  const statusEventType = isEpicOpen ? statusEvent.close : statusEvent.reopen;
  const queryParam = `epic[state_event]=${statusEventType}`;

  axios
    .put(`${state.endpoint}.json?${encodeURI(queryParam)}`)
    .then(({ data }) => {
      dispatch('requestEpicStatusChangeSuccess', data);
      dispatch('triggerIssuableEvent', { isEpicOpen: data.state === statusType.close });
    })
    .catch(() => {
      dispatch('requestEpicStatusChangeFailure');
      dispatch('triggerIssuableEvent', { isEpicOpen: !isEpicOpen });
    });
};

export const toggleSidebarFlag = ({ commit }, sidebarCollapsed) =>
  commit(types.TOGGLE_SIDEBAR, sidebarCollapsed);
export const toggleContainerClassAndCookie = (_, sidebarCollapsed) => {
  epicUtils.toggleContainerClass('right-sidebar-expanded');
  epicUtils.toggleContainerClass('right-sidebar-collapsed');

  epicUtils.setCollapsedGutter(sidebarCollapsed);
};
export const toggleSidebar = ({ dispatch }, { sidebarCollapsed }) => {
  dispatch('toggleContainerClassAndCookie', !sidebarCollapsed);
  dispatch('toggleSidebarFlag', !sidebarCollapsed);
};

/**
 * Methods to handle toggling Todo from sidebar
 */
export const requestEpicTodoToggle = ({ commit }) => commit(types.REQUEST_EPIC_TODO_TOGGLE);
export const requestEpicTodoToggleSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_TODO_TOGGLE_SUCCESS, data);
export const requestEpicTodoToggleFailure = ({ commit, state }, data) => {
  commit(types.REQUEST_EPIC_TODO_TOGGLE_FAILURE, data);

  if (state.todoExists) {
    flash(__('There was an error deleting the To Do.'));
  } else {
    flash(__('There was an error adding a To Do.'));
  }
};
export const triggerTodoToggleEvent = (_, { count }) => {
  epicUtils.triggerDocumentEvent('todo:toggle', count);
};
export const toggleTodo = ({ state, dispatch }) => {
  let reqPromise;

  dispatch('requestEpicTodoToggle');

  if (!state.todoExists) {
    reqPromise = axios.post(state.todoPath, {
      issuable_id: state.epicId,
      issuable_type: 'epic',
    });
  } else {
    reqPromise = axios.delete(state.todoDeletePath);
  }

  reqPromise
    .then(({ data }) => {
      dispatch('triggerTodoToggleEvent', { count: data.count });
      dispatch('requestEpicTodoToggleSuccess', { todoDeletePath: data.delete_path });
    })
    .catch(() => {
      dispatch('requestEpicTodoToggleFailure');
    });
};

/**
 * Methods to handle Epic start and due date manipulations from sidebar
 */
export const toggleStartDateType = ({ commit }, data) =>
  commit(types.TOGGLE_EPIC_START_DATE_TYPE, data);
export const toggleDueDateType = ({ commit }, data) =>
  commit(types.TOGGLE_EPIC_DUE_DATE_TYPE, data);
export const requestEpicDateSave = ({ commit }, data) => commit(types.REQUEST_EPIC_DATE_SAVE, data);
export const requestEpicDateSaveSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_DATE_SAVE_SUCCESS, data);
export const requestEpicDateSaveFailure = ({ commit }, data) => {
  commit(types.REQUEST_EPIC_DATE_SAVE_FAILURE, data);
  flash(
    sprintf(s__('Epics|An error occurred while saving the %{epicDateType} date'), {
      epicDateType: dateTypes.start === data.dateType ? s__('Epics|start') : s__('Epics|due'),
    }),
  );
};
export const saveDate = ({ state, dispatch }, { dateType, dateTypeIsFixed, newDate }) => {
  const updateEpicInput = {
    iid: `${state.epicIid}`,
    groupPath: state.fullPath,
    [dateType === dateTypes.start ? 'startDateIsFixed' : 'dueDateIsFixed']: dateTypeIsFixed,
  };

  if (dateTypeIsFixed) {
    updateEpicInput[dateType === dateTypes.start ? 'startDateFixed' : 'dueDateFixed'] = newDate;
  }

  dispatch('requestEpicDateSave', { dateType });
  epicUtils.gqClient
    .mutate({
      mutation: updateEpic,
      variables: {
        updateEpicInput,
      },
    })
    .then(({ data }) => {
      if (!data?.updateEpic?.errors.length) {
        dispatch('requestEpicDateSaveSuccess', {
          dateType,
          dateTypeIsFixed,
          newDate,
        });
      } else {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        throw new Error('An error occurred while saving the date');
      }
    })
    .catch(() => {
      dispatch('requestEpicDateSaveFailure', {
        dateType,
        dateTypeIsFixed: !dateTypeIsFixed,
      });
    });
};

export const updateConfidentialityOnIssuable = ({ state, commit }, { confidential }) => {
  const updateEpicInput = {
    iid: `${state.epicIid}`,
    groupPath: state.fullPath,
    confidential,
  };

  return epicUtils.gqClient
    .mutate({
      mutation: updateEpic,
      variables: {
        updateEpicInput,
      },
    })
    .then(({ data }) => {
      if (!data?.updateEpic?.errors.length) {
        commit(types.SET_EPIC_CONFIDENTIAL, confidential);
      } else {
        const errMsg =
          data?.updateEpic?.errors[0]?.replace(/Confidential /, '') ||
          s__('Epics|Unable to perform this action');
        throw errMsg;
      }
    })
    .catch(error => {
      flash(error);
      throw error;
    });
};

/**
 * Methods to handle Epic labels selection from sidebar
 */
export const requestEpicLabelsSelect = ({ commit }) => commit(types.REQUEST_EPIC_LABELS_SELECT);
export const receiveEpicLabelsSelectSuccess = ({ commit }, labels) =>
  commit(types.RECEIVE_EPIC_LABELS_SELECT_SUCCESS, labels);
export const receiveEpicLabelsSelectFailure = ({ commit }) => {
  commit(types.RECEIVE_EPIC_LABELS_SELECT_FAILURE);
  flash(s__('Epics|An error occurred while updating labels.'));
};
export const updateEpicLabels = ({ dispatch, state }, labels) => {
  const addLabelIds = labels.filter(label => label.set).map(label => label.id);
  const removeLabelIds = labels.filter(label => !label.set).map(label => label.id);
  const updateEpicInput = {
    iid: `${state.epicIid}`,
    groupPath: state.fullPath,
    addLabelIds,
    removeLabelIds,
  };

  dispatch('requestEpicLabelsSelect');
  epicUtils.gqClient
    .mutate({
      mutation: updateEpic,
      variables: {
        updateEpicInput,
      },
    })
    .then(({ data }) => {
      if (!data?.updateEpic?.errors.length) {
        dispatch('receiveEpicLabelsSelectSuccess', labels);
      } else {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        throw new Error('An error occurred while updating labels');
      }
    })
    .catch(() => {
      dispatch('receiveEpicLabelsSelectFailure');
    });
};

/**
 * Methods to handle Epic subscription (AKA Notifications) toggle from sidebar
 */
export const requestEpicSubscriptionToggle = ({ commit }) =>
  commit(types.REQUEST_EPIC_SUBSCRIPTION_TOGGLE);
export const requestEpicSubscriptionToggleSuccess = ({ commit }, data) =>
  commit(types.REQUEST_EPIC_SUBSCRIPTION_TOGGLE_SUCCESS, data);
export const requestEpicSubscriptionToggleFailure = ({ commit, state }) => {
  commit(types.REQUEST_EPIC_SUBSCRIPTION_TOGGLE_FAILURE);
  if (state.subscribed) {
    flash(__('An error occurred while unsubscribing to notifications.'));
  } else {
    flash(__('An error occurred while subscribing to notifications.'));
  }
};
export const toggleEpicSubscription = ({ state, dispatch }) => {
  dispatch('requestEpicSubscriptionToggle');
  epicUtils.gqClient
    .mutate({
      mutation: epicSetSubscription,
      variables: {
        epicSetSubscriptionInput: {
          iid: `${state.epicIid}`,
          groupPath: state.fullPath,
          subscribedState: !state.subscribed,
        },
      },
    })
    .then(({ data }) => {
      if (!data?.epicSetSubscription?.errors.length) {
        dispatch('requestEpicSubscriptionToggleSuccess', {
          subscribed: !state.subscribed,
        });
      } else {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        throw new Error('An error occurred while toggling to notifications.');
      }
    })
    .catch(() => {
      dispatch('requestEpicSubscriptionToggleFailure');
    });
};

/**
 * Methods to handle Epic create from Epics index page
 */
export const setEpicCreateTitle = ({ commit }, data) => commit(types.SET_EPIC_CREATE_TITLE, data);
export const setEpicCreateConfidential = ({ commit }, data) =>
  commit(types.SET_EPIC_CREATE_CONFIDENTIAL, data);
export const requestEpicCreate = ({ commit }) => commit(types.REQUEST_EPIC_CREATE);
export const requestEpicCreateSuccess = (_, webUrl) => visitUrl(webUrl);
export const requestEpicCreateFailure = ({ commit }) => {
  commit(types.REQUEST_EPIC_CREATE_FAILURE);
  flash(s__('Error creating epic'));
};
export const createEpic = ({ state, dispatch }) => {
  dispatch('requestEpicCreate');
  axios
    .post(state.endpoint, {
      title: state.newEpicTitle,
      confidential: state.newEpicConfidential,
    })
    .then(({ data }) => {
      dispatch('requestEpicCreateSuccess', data.web_url);
    })
    .catch(() => {
      dispatch('requestEpicCreateFailure');
    });
};
