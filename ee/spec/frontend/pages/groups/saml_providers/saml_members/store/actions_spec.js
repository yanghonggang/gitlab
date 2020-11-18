import { fetchPage } from 'ee/pages/groups/saml_providers/saml_members/store/actions';
import * as types from 'ee/pages/groups/saml_providers/saml_members/store/mutation_types';
import createInitialState from 'ee/pages/groups/saml_providers/saml_members/store/state';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';

import { deprecatedCreateFlash as flash } from '~/flash';

jest.mock('~/flash');
jest.mock('~/api', () => ({
  groupMembers: jest.fn(),
}));

const state = {
  ...createInitialState(),
  groupId: 1,
};

describe('saml_members actions', () => {
  afterEach(() => {
    Api.groupMembers.mockClear();
    flash.mockClear();
  });

  describe('fetchPage', () => {
    it('should commit RECEIVE_SAML_MEMBERS_SUCCESS mutation on correct data', done => {
      const members = [
        { id: 1, name: 'user 1', group_saml_identity: null },
        { id: 2, name: 'user 2', group_saml_identity: { extern_uid: 'a' } },
      ];

      const expectedMembers = [
        { id: 1, name: 'user 1', identity: null },
        { id: 2, name: 'user 2', identity: 'a' },
      ];

      Api.groupMembers.mockReturnValue(
        Promise.resolve({
          headers: {
            'x-per-page': '10',
            'x-page': '2',
            'x-total': '30',
            'x-total-pages': '3',
            'x-next-page': '3',
            'x-prev-page': '1',
          },
          data: members,
        }),
      );

      const expectedPageInfo = {
        perPage: 10,
        page: 2,
        total: 30,
        totalPages: 3,
        nextPage: 3,
        previousPage: 1,
      };

      testAction(
        fetchPage,
        undefined,
        state,
        [
          {
            type: types.RECEIVE_SAML_MEMBERS_SUCCESS,
            payload: { members: expectedMembers, pageInfo: expectedPageInfo },
          },
        ],
        [],
        done,
      );
    });

    it('should show flash on wrong data', done => {
      Api.groupMembers.mockReturnValue(Promise.reject(new Error()));
      testAction(fetchPage, undefined, state, [], [], () => {
        expect(flash).toHaveBeenCalledTimes(1);
        done();
      });
    });
  });
});
