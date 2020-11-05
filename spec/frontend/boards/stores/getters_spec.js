import getters from '~/boards/stores/getters';
import { inactiveId } from '~/boards/constants';
import {
  mockIssue,
  mockIssue2,
  mockIssues,
  mockIssuesByListId,
  issues,
  mockListsWithModel,
} from '../mock_data';

describe('Boards - Getters', () => {
  describe('getLabelToggleState', () => {
    it('should return "on" when isShowingLabels is true', () => {
      const state = {
        isShowingLabels: true,
      };

      expect(getters.getLabelToggleState(state)).toBe('on');
    });

    it('should return "off" when isShowingLabels is false', () => {
      const state = {
        isShowingLabels: false,
      };

      expect(getters.getLabelToggleState(state)).toBe('off');
    });
  });

  describe('isSidebarOpen', () => {
    it('returns true when activeId is not equal to 0', () => {
      const state = {
        activeId: 1,
      };

      expect(getters.isSidebarOpen(state)).toBe(true);
    });

    it('returns false when activeId is equal to 0', () => {
      const state = {
        activeId: inactiveId,
      };

      expect(getters.isSidebarOpen(state)).toBe(false);
    });
  });

  describe('isSwimlanesOn', () => {
    afterEach(() => {
      window.gon = { features: {} };
    });

    describe('when boardsWithSwimlanes is true', () => {
      beforeEach(() => {
        window.gon = { features: { boardsWithSwimlanes: true } };
      });

      describe('when isShowingEpicsSwimlanes is true', () => {
        it('returns true', () => {
          const state = {
            isShowingEpicsSwimlanes: true,
          };

          expect(getters.isSwimlanesOn(state)).toBe(true);
        });
      });

      describe('when isShowingEpicsSwimlanes is false', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: false,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });
    });

    describe('when boardsWithSwimlanes is false', () => {
      describe('when isShowingEpicsSwimlanes is true', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: true,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });

      describe('when isShowingEpicsSwimlanes is false', () => {
        it('returns false', () => {
          const state = {
            isShowingEpicsSwimlanes: false,
          };

          expect(getters.isSwimlanesOn(state)).toBe(false);
        });
      });
    });
  });

  describe('getIssueById', () => {
    const state = { issues: { '1': 'issue' } };

    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{}}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      expect(getters.getIssueById(state)(id)).toEqual(expected);
    });
  });

  describe('getActiveIssue', () => {
    it.each`
      id     | expected
      ${'1'} | ${'issue'}
      ${''}  | ${{}}
    `('returns $expected when $id is passed to state', ({ id, expected }) => {
      const state = { issues: { '1': 'issue' }, activeId: id };

      expect(getters.getActiveIssue(state)).toEqual(expected);
    });
  });

  describe('getIssues', () => {
    const boardsState = {
      issuesByListId: mockIssuesByListId,
      issues,
    };
    it('returns issues for a given listId', () => {
      const getIssueById = issueId => [mockIssue, mockIssue2].find(({ id }) => id === issueId);

      expect(getters.getIssues(boardsState, { getIssueById })('gid://gitlab/List/2')).toEqual(
        mockIssues,
      );
    });
  });

  const boardsState = {
    boardLists: {
      'gid://gitlab/List/1': mockListsWithModel[0],
      'gid://gitlab/List/2': mockListsWithModel[1],
    },
  };

  describe('getListByLabelId', () => {
    it('returns list for a given label id', () => {
      expect(getters.getListByLabelId(boardsState)('gid://gitlab/GroupLabel/121')).toEqual(
        mockListsWithModel[1],
      );
    });
  });

  describe('getListByTitle', () => {
    it('returns list for a given list title', () => {
      expect(getters.getListByTitle(boardsState)('To Do')).toEqual(mockListsWithModel[1]);
    });
  });
});
