import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { noop } from 'lodash';
import {
  updateLdapOverride,
  showLdapOverrideConfirmationModal,
  hideLdapOverrideConfirmationModal,
} from 'ee/vuex_shared/modules/members/actions';
import * as types from 'ee/vuex_shared/modules/members/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import { members, member } from 'jest/vue_shared/components/members/mock_data';
import httpStatusCodes from '~/lib/utils/http_status';

describe('Vuex members actions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('updateLdapOverride', () => {
    const payload = {
      memberId: members[0].id,
      override: true,
    };

    const state = {
      members,
      ldapOverridePath: '/groups/ldap-group/-/group_members/:id/override',
      requestFormatter: noop,
    };

    describe('successful request', () => {
      it(`commits ${types.RECEIVE_LDAP_OVERRIDE_SUCCESS} mutation`, async () => {
        mock.onPatch().replyOnce(httpStatusCodes.OK);

        await testAction(updateLdapOverride, payload, state, [
          {
            type: types.RECEIVE_LDAP_OVERRIDE_SUCCESS,
            payload,
          },
        ]);

        expect(mock.history.patch[0].url).toBe('/groups/ldap-group/-/group_members/238/override');
      });
    });

    describe('unsuccessful request', () => {
      beforeEach(() => {
        mock.onPatch().networkError();
      });

      it(`commits ${types.RECEIVE_LDAP_OVERRIDE_ERROR} mutation and throws error`, async () => {
        await expect(
          testAction(updateLdapOverride, {}, state, [
            {
              type: types.RECEIVE_LDAP_OVERRIDE_ERROR,
            },
          ]),
        ).rejects.toThrowError(new Error('Network Error'));
      });
    });
  });

  describe('LDAP override confirmation modal', () => {
    const state = {
      memberToOverride: null,
      ldapOverrideConfirmationModalVisible: false,
    };

    describe('showLdapOverrideConfirmationModal', () => {
      it(`commits ${types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL} mutation`, () => {
        testAction(showLdapOverrideConfirmationModal, member, state, [
          {
            type: types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL,
            payload: member,
          },
        ]);
      });
    });

    describe('hideLdapOverrideConfirmationModal', () => {
      it(`commits ${types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL} mutation`, () => {
        testAction(hideLdapOverrideConfirmationModal, {}, state, [
          {
            type: types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL,
          },
        ]);
      });
    });
  });
});
