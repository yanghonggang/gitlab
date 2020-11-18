import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  tokenKeys,
  alternativeTokenKeys,
  conditions,
} from '~/filtered_search/issuable_filtered_search_token_keys';
import { __ } from '~/locale';

export const weightTokenKey = {
  formattedKey: __('Weight'),
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'weight',
  tag: 'number',
};

export const epicTokenKey = {
  formattedKey: __('Epic'),
  key: 'epic',
  type: 'string',
  param: 'id',
  symbol: '&',
  icon: 'epic',
};

export const iterationTokenKey = {
  formattedKey: __('Iteration'),
  key: 'iteration',
  type: 'string',
  param: 'title',
  symbol: '',
  icon: 'iteration',
};

export const weightConditions = [
  {
    url: 'weight=None',
    operator: '=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'weight=Any',
    operator: '=',
    tokenKey: 'weight',
    value: __('Any'),
  },
  {
    url: 'not[weight]=None',
    operator: '!=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'not[weight]=Any',
    operator: '!=',
    tokenKey: 'weight',
    value: __('Any'),
  },
];

export const epicConditions = [
  {
    url: 'epic_id=None',
    operator: '=',
    tokenKey: 'epic',
    value: __('None'),
  },
  {
    url: 'epic_id=Any',
    operator: '=',
    tokenKey: 'epic',
    value: __('Any'),
  },
  {
    url: 'not[epic_id]=None',
    operator: '!=',
    tokenKey: 'epic',
    value: __('None'),
  },
  {
    url: 'not[epic_id]=Any',
    operator: '!=',
    tokenKey: 'epic',
    value: __('Any'),
  },
];

export const iterationConditions = [
  {
    url: 'iteration_id=None',
    operator: '=',
    tokenKey: 'iteration',
    value: __('None'),
  },
  {
    url: 'iteration_id=Any',
    operator: '=',
    tokenKey: 'iteration',
    value: __('Any'),
  },
];

/**
 * Filter tokens for issues in EE.
 */
class IssuesFilteredSearchTokenKeysEE extends FilteredSearchTokenKeys {
  constructor() {
    const milestoneTokenKeyIndex = tokenKeys.findIndex(tk => tk.key === 'milestone');
    tokenKeys.splice(milestoneTokenKeyIndex + 1, 0, iterationTokenKey);

    super([...tokenKeys, epicTokenKey, weightTokenKey], alternativeTokenKeys, [
      ...conditions,
      ...weightConditions,
      ...epicConditions,
      ...iterationConditions,
    ]);
  }

  /**
   * Changes assignee token to accept multiple values.
   */
  enableMultipleAssignees() {
    const assigneeTokenKey = this.tokenKeys.find(tk => tk.key === 'assignee');

    // Add the original as an alternative token key
    this.tokenKeysWithAlternative.push({ ...assigneeTokenKey });

    assigneeTokenKey.type = 'array';
    assigneeTokenKey.param = 'username[]';
  }

  removeEpicToken() {
    this.removeToken(epicTokenKey);
  }

  removeIterationToken() {
    this.removeToken(iterationTokenKey);
  }

  removeToken(tokenKey) {
    const index = this.tokenKeys.findIndex(token => token.key === tokenKey.key);
    if (index >= 0) {
      this.tokenKeys.splice(index, 1);
    }
  }
}

export default new IssuesFilteredSearchTokenKeysEE();
