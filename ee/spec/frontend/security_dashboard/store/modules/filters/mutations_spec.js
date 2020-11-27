import { severityFilter } from 'ee/security_dashboard/helpers';
import {
  SET_FILTER,
  SET_HIDE_DISMISSED,
} from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';
import createState from 'ee/security_dashboard/store/modules/filters/state';
import { DISMISSAL_STATES } from 'ee/security_dashboard/store/modules/filters/constants';

const criticalOption = severityFilter.options.find(x => x.id === 'CRITICAL');
const highOption = severityFilter.options.find(x => x.id === 'HIGH');

const existingFilters = {
  filter1: ['some', 'value'],
  filter2: ['other', 'values'],
};

describe('filters module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('SET_FILTER', () => {
    it.each`
      options
      ${[]}
      ${[criticalOption.id]}
      ${[criticalOption.id, highOption.id]}
    `('sets the filter to $options', ({ options }) => {
      mutations[SET_FILTER](state, { [severityFilter.id]: options });

      expect(state.filters[severityFilter.id]).toEqual(options);
    });

    it('adds new filter to existing filters', () => {
      const newFilter = { filter3: ['custom', 'filters'] };
      state.filters = existingFilters;
      mutations[SET_FILTER](state, newFilter);

      expect(state.filters).toEqual({ ...existingFilters, ...newFilter });
    });
  });

  describe('SET_HIDE_DISMISSED', () => {
    it.each(Object.values(DISMISSAL_STATES))(`sets scope filter to "%s"`, value => {
      mutations[SET_HIDE_DISMISSED](state, value);
      expect(state.filters.scope).toBe(value);
    });

    it('adds scope filter to existing filters', () => {
      state.filters = existingFilters;
      mutations[SET_HIDE_DISMISSED](state, 'dismissed');

      expect(state.filters).toEqual({ ...existingFilters, scope: 'dismissed' });
    });
  });
});
