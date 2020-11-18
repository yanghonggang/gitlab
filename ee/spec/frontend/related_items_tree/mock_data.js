import { ChildState } from 'ee/related_items_tree/constants';
import { TEST_HOST } from 'spec/test_constants';

export const mockInitialConfig = {
  epicsEndpoint: `${TEST_HOST}/epics`,
  issuesEndpoint: `${TEST_HOST}/issues`,
  projectsEndpoint: `${TEST_HOST}/projects`,
  autoCompleteEpics: true,
  autoCompleteIssues: false,
  userSignedIn: true,
  allowSubEpics: true,
};

export const mockParentItem = {
  id: 'gid://gitlab/Epic/42',
  iid: 1,
  fullPath: 'gitlab-org',
  title: 'Some sample epic',
  reference: 'gitlab-org&1',
  type: 'Epic',
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 2,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
};

export const mockParentItem2 = {
  id: 'gid://gitlab/Epic/43',
  iid: 2,
  fullPath: 'gitlab-org',
  title: 'Some sample epic 2',
  reference: 'gitlab-org&2',
  parentReference: 'gitlab-org&2',
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 1,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
};

export const mockEpic1 = {
  id: 'gid://gitlab/Epic/4',
  iid: '4',
  title: 'Quo ea ipsa enim perferendis at omnis officia.',
  state: ChildState.Open,
  webPath: '/groups/gitlab-org/-/epics/4',
  reference: '&4',
  relationPath: '/groups/gitlab-org/-/epics/1/links/4',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: null,
  hasChildren: true,
  hasIssues: true,
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
  healthStatus: {
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
    issuesOnTrack: 0,
  },
};

export const mockEpic2 = {
  id: 'gid://gitlab/Epic/3',
  iid: '3',
  title: 'A nisi mollitia explicabo quam soluta dolor hic.',
  state: ChildState.Closed,
  webPath: '/groups/gitlab-org/-/epics/3',
  reference: '&3',
  relationPath: '/groups/gitlab-org/-/epics/1/links/3',
  createdAt: '2019-02-18T14:13:06Z',
  closedAt: '2019-04-26T06:51:22Z',
  hasChildren: false,
  hasIssues: false,
  userPermissions: {
    adminEpic: true,
    createEpic: true,
  },
  group: {
    fullPath: 'gitlab-org',
  },
  healthStatus: {
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
    issuesOnTrack: 0,
  },
};

// Epic meta data for having some open issues
export const mockEpicMeta1 = {
  descendantCounts: {
    openedEpics: 1,
    closedEpics: 1,
    openedIssues: 2,
    closedIssues: 1,
  },
  healthStatus: {
    issuesOnTrack: 1,
    issuesAtRisk: 0,
    issuesNeedingAttention: 1,
  },
};

// Epic meta data for having no open issues
export const mockEpicMeta2 = {
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 1,
    openedIssues: 0,
    closedIssues: 2,
  },
  healthStatus: {
    issuesOnTrack: 0,
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
  },
};

// Epic meta data for having no child issues
export const mockEpicMeta3 = {
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 1,
    openedIssues: 0,
    closedIssues: 0,
  },
  healthStatus: {
    issuesOnTrack: 0,
    issuesAtRisk: 0,
    issuesNeedingAttention: 0,
  },
};

export const mockIssue1 = {
  iid: '8',
  epicIssueId: 'gid://gitlab/EpicIssue/3',
  title: 'Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.',
  closedAt: null,
  state: ChildState.Open,
  createdAt: '2019-02-18T14:06:41Z',
  confidential: true,
  dueDate: '2019-06-14',
  weight: 5,
  webPath: '/gitlab-org/gitlab-shell/issues/8',
  reference: 'gitlab-org/gitlab-shell#8',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/10',
  assignees: {
    edges: [
      {
        node: {
          webUrl: 'http://127.0.0.1:3001/root',
          name: 'Administrator',
          username: 'root',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
        },
      },
    ],
  },
  milestone: {
    title: 'v4.0',
    startDate: '2019-02-01',
    dueDate: '2019-06-30',
  },
  healthStatus: 'onTrack',
};

export const mockIssue2 = {
  iid: '33',
  epicIssueId: 'gid://gitlab/EpicIssue/4',
  title: 'Dismiss Cipher with no integrity',
  closedAt: null,
  state: ChildState.Open,
  createdAt: '2019-02-18T14:13:05Z',
  confidential: false,
  dueDate: null,
  weight: null,
  webPath: '/gitlab-org/gitlab-shell/issues/33',
  reference: 'gitlab-org/gitlab-shell#33',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/27',
  assignees: {
    edges: [],
  },
  milestone: null,
  healthStatus: 'needsAttention',
};

export const mockClosedIssue = {
  iid: '42',
  epicIssueId: 'gid://gitlab/EpicIssue/5',
  title: 'View closed issues in epic',
  closedAt: null,
  state: ChildState.Closed,
  createdAt: '2019-02-18T14:13:05Z',
  confidential: false,
  dueDate: null,
  weight: null,
  webPath: '/gitlab-org/gitlab-shell/issues/42',
  reference: 'gitlab-org/gitlab-shell#42',
  relationPath: '/groups/gitlab-org/-/epics/1/issues/27',
  assignees: {
    edges: [],
  },
  milestone: null,
  healthStatus: 'atRisk',
};

export const mockEpics = [mockEpic1, mockEpic2];

export const mockIssues = [mockIssue1, mockIssue2, mockClosedIssue];

export const mockQueryResponse = {
  data: {
    group: {
      id: 1,
      path: 'gitlab-org',
      fullPath: 'gitlab-org',
      epic: {
        id: 1,
        iid: 1,
        title: 'Foo bar',
        webPath: '/groups/gitlab-org/-/epics/1',
        userPermissions: {
          adminEpic: true,
          createEpic: true,
        },
        children: {
          edges: [
            {
              node: mockEpic1,
            },
            {
              node: mockEpic2,
            },
          ],
          pageInfo: {
            endCursor: 'abc',
            hasNextPage: true,
          },
        },
        issues: {
          edges: [
            {
              node: mockIssue1,
            },
            {
              node: mockIssue2,
            },
            {
              node: mockClosedIssue,
            },
          ],
          pageInfo: {
            endCursor: 'def',
            hasNextPage: true,
          },
        },
        descendantCounts: mockParentItem.descendantCounts,
        healthStatus: {
          atRisk: 0,
          needsAttention: 1,
          onTrack: 1,
        },
      },
    },
  },
};

export const mockQueryResponse2 = {
  data: {
    group: {
      id: 1,
      path: 'gitlab-org',
      fullPath: 'gitlab-org',
      epic: {
        id: 1,
        iid: 1,
        title: 'Foo bar',
        webPath: '/groups/gitlab-org/-/epics/1',
        userPermissions: {
          adminEpic: true,
          createEpic: true,
        },
        children: {
          edges: [
            {
              node: mockEpic1,
            },
            {
              node: mockEpic2,
            },
          ],
          pageInfo: {
            endCursor: 'abc',
            hasNextPage: true,
          },
        },
        issues: {
          edges: [
            {
              node: mockClosedIssue,
            },
            {
              node: mockIssue1,
            },
            {
              node: mockIssue2,
            },
          ],
          pageInfo: {
            endCursor: 'def',
            hasNextPage: true,
          },
        },
      },
    },
  },
};

export const mockReorderMutationResponse = {
  epicTreeReorder: {
    clientMutationId: null,
    errors: [],
    __typename: 'EpicTreeReorderPayload',
  },
};

export const mockEpicTreeReorderInput = {
  baseEpicId: 'gid://gitlab/Epic/1',
  moved: {
    id: 'gid://gitlab/Epic/2',
    moveAfterId: 'gid://gitlab/Epic/3',
  },
};
