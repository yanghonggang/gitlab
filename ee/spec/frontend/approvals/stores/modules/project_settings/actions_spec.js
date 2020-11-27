import MockAdapter from 'axios-mock-adapter';
import { mapApprovalRuleRequest, mapApprovalSettingsResponse } from 'ee/approvals/mappers';
import * as types from 'ee/approvals/stores/modules/base/mutation_types';
import * as actions from 'ee/approvals/stores/modules/project_settings/actions';
import testAction from 'helpers/vuex_action_helper';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/flash');

const TEST_PROJECT_ID = 9;
const TEST_RULE_ID = 7;
const TEST_RULE_REQUEST = {
  name: 'Lorem',
  approvalsRequired: 1,
  groups: [7],
  users: [8, 9],
};
const TEST_RULE_RESPONSE = {
  id: 7,
  name: 'Ipsum',
  approvals_required: 2,
  approvers: [{ id: 7 }, { id: 8 }, { id: 9 }],
  groups: [{ id: 4 }],
  users: [{ id: 7 }, { id: 8 }],
};
const TEST_SETTINGS_PATH = 'projects/9/approval_settings';
const TEST_RULES_PATH = 'projects/9/approval_settings/rules';

describe('EE approvals project settings module actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = {
      settings: {
        projectId: TEST_PROJECT_ID,
        settingsPath: TEST_SETTINGS_PATH,
        rulesPath: TEST_RULES_PATH,
      },
    };
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('requestRules', () => {
    it('sets loading', () => {
      return testAction(
        actions.requestRules,
        null,
        {},
        [{ type: types.SET_LOADING, payload: true }],
        [],
      );
    });
  });

  describe('receiveRulesSuccess', () => {
    it('sets rules', () => {
      const settings = { rules: [{ id: 1 }] };

      return testAction(
        actions.receiveRulesSuccess,
        settings,
        {},
        [
          { type: types.SET_APPROVAL_SETTINGS, payload: settings },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
      );
    });
  });

  describe('receiveRulesError', () => {
    it('creates a flash', () => {
      expect(createFlash).not.toHaveBeenCalled();

      actions.receiveRulesError();

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith(expect.stringMatching('error occurred'));
    });
  });

  describe('fetchRules', () => {
    it('dispatches request/receive', () => {
      const data = { rules: [TEST_RULE_RESPONSE] };
      mock.onGet(TEST_SETTINGS_PATH).replyOnce(200, data);

      return testAction(
        actions.fetchRules,
        null,
        state,
        [],
        [
          { type: 'requestRules' },
          { type: 'receiveRulesSuccess', payload: mapApprovalSettingsResponse(data) },
        ],
        () => {
          expect(mock.history.get.map(x => x.url)).toEqual([TEST_SETTINGS_PATH]);
        },
      );
    });

    it('dispatches request/receive on error', () => {
      mock.onGet(TEST_SETTINGS_PATH).replyOnce(500);

      return testAction(
        actions.fetchRules,
        null,
        state,
        [],
        [{ type: 'requestRules' }, { type: 'receiveRulesError' }],
      );
    });
  });

  describe('postRuleSuccess', () => {
    it('closes modal and fetches', () => {
      return testAction(
        actions.postRuleSuccess,
        null,
        {},
        [],
        [{ type: 'createModal/close' }, { type: 'fetchRules' }],
      );
    });
  });

  describe('postRule', () => {
    it('dispatches success on success', () => {
      mock.onPost(TEST_RULES_PATH).replyOnce(200);

      return testAction(
        actions.postRule,
        TEST_RULE_REQUEST,
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(mock.history.post).toEqual([
            expect.objectContaining({
              url: TEST_RULES_PATH,
              data: JSON.stringify(mapApprovalRuleRequest(TEST_RULE_REQUEST)),
            }),
          ]);
        },
      );
    });
  });

  describe('putRule', () => {
    it('dispatches success on success', () => {
      mock.onPut(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(200);

      return testAction(
        actions.putRule,
        { id: TEST_RULE_ID, ...TEST_RULE_REQUEST },
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(mock.history.put).toEqual([
            expect.objectContaining({
              url: `${TEST_RULES_PATH}/${TEST_RULE_ID}`,
              data: JSON.stringify(mapApprovalRuleRequest(TEST_RULE_REQUEST)),
            }),
          ]);
        },
      );
    });
  });

  describe('deleteRuleSuccess', () => {
    it('closes modal and fetches', () => {
      return testAction(
        actions.deleteRuleSuccess,
        null,
        {},
        [],
        [{ type: 'deleteModal/close' }, { type: 'fetchRules' }],
      );
    });
  });

  describe('deleteRuleError', () => {
    it('creates a flash', () => {
      expect(createFlash).not.toHaveBeenCalled();

      actions.deleteRuleError();

      expect(createFlash.mock.calls[0]).toEqual([expect.stringMatching('error occurred')]);
    });
  });

  describe('deleteRule', () => {
    it('dispatches success on success', () => {
      mock.onDelete(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(200);

      return testAction(
        actions.deleteRule,
        TEST_RULE_ID,
        state,
        [],
        [{ type: 'deleteRuleSuccess' }],
        () => {
          expect(mock.history.delete).toEqual([
            expect.objectContaining({
              url: `${TEST_RULES_PATH}/${TEST_RULE_ID}`,
            }),
          ]);
        },
      );
    });

    it('dispatches error on error', () => {
      mock.onDelete(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(500);

      return testAction(actions.deleteRule, TEST_RULE_ID, state, [], [{ type: 'deleteRuleError' }]);
    });
  });
});
