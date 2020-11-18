import { GlEmptyState, GlSprintf, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import JiraIssuesListEmptyState from 'ee/integrations/jira/issues_list/components/jira_issues_list_empty_state.vue';
import { IssuableStates } from '~/issuable_list/constants';

import { mockProvide } from '../mock_data';

const createComponent = (props = {}) =>
  shallowMount(JiraIssuesListEmptyState, {
    provide: mockProvide,
    propsData: {
      currentState: 'opened',
      issuesCount: {
        [IssuableStates.Opened]: 0,
        [IssuableStates.Closed]: 0,
        [IssuableStates.All]: 0,
      },
      hasFiltersApplied: false,
      ...props,
    },
    stubs: { GlEmptyState },
  });

describe('JiraIssuesListEmptyState', () => {
  const titleDefault =
    'Issues created in Jira are shown here once you have created the issues in project setup in Jira.';
  const titleWhenFilters = 'Sorry, your filter produced no results';
  const titleWhenIssues = 'There are no open issues';

  const descriptionWhenFilters = 'To widen your search, change or remove filters above';
  const descriptionWhenNoIssues = 'To keep this project going, create a new issue.';
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('hasIssues', () => {
      it('returns false when total of opened and closed issues within `issuesCount` is 0', () => {
        expect(wrapper.vm.hasIssues).toBe(false);
      });

      it('returns true when total of opened and closed issues within `issuesCount` is more than 0', async () => {
        wrapper.setProps({
          issuesCount: {
            [IssuableStates.Opened]: 1,
            [IssuableStates.Closed]: 1,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.hasIssues).toBe(true);
      });
    });

    describe('emptyStateTitle', () => {
      it(`returns string "${titleWhenFilters}" when hasFiltersApplied prop is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: true,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe(titleWhenFilters);
      });

      it(`returns string "${titleWhenIssues}" when hasFiltersApplied prop is false and hasIssues is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
          issuesCount: {
            [IssuableStates.Opened]: 1,
            [IssuableStates.Closed]: 1,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe(titleWhenIssues);
      });

      it('returns default title string when both hasFiltersApplied and hasIssues props are false', async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateTitle).toBe(titleDefault);
      });
    });

    describe('emptyStateDescription', () => {
      it(`returns string "${descriptionWhenFilters}" when hasFiltersApplied prop is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: true,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe(descriptionWhenFilters);
      });

      it(`returns string "${descriptionWhenNoIssues}" when both hasFiltersApplied and hasIssues props are false`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe(descriptionWhenNoIssues);
      });

      it(`returns empty string when hasFiltersApplied is false and hasIssues is true`, async () => {
        wrapper.setProps({
          hasFiltersApplied: false,
          issuesCount: {
            [IssuableStates.Opened]: 1,
            [IssuableStates.Closed]: 1,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.emptyStateDescription).toBe('');
      });
    });
  });

  describe('template', () => {
    it('renders gl-empty-state component', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });

    it('renders empty state title', async () => {
      const emptyStateEl = wrapper.find(GlEmptyState);

      expect(emptyStateEl.props()).toMatchObject({
        svgPath: mockProvide.emptyStatePath,
        title:
          'Issues created in Jira are shown here once you have created the issues in project setup in Jira.',
      });

      wrapper.setProps({
        hasFiltersApplied: true,
      });

      await wrapper.vm.$nextTick();

      expect(emptyStateEl.props('title')).toBe('Sorry, your filter produced no results');

      wrapper.setProps({
        hasFiltersApplied: false,
        issuesCount: {
          [IssuableStates.Opened]: 1,
          [IssuableStates.Closed]: 1,
        },
      });

      await wrapper.vm.$nextTick();

      expect(emptyStateEl.props('title')).toBe('There are no open issues');
    });

    it('renders empty state description', () => {
      const descriptionEl = wrapper.find(GlSprintf);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.attributes('message')).toBe(
        'To keep this project going, create a new issue.',
      );
    });

    it('does not render empty state description when issues are present', async () => {
      wrapper.setProps({
        issuesCount: {
          [IssuableStates.Opened]: 1,
          [IssuableStates.Closed]: 1,
        },
      });

      await wrapper.vm.$nextTick();

      const descriptionEl = wrapper.find(GlSprintf);

      expect(descriptionEl.exists()).toBe(false);
    });

    it('renders "Create new issue in Jira" button', () => {
      const buttonEl = wrapper.find(GlButton);

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.attributes('href')).toBe(mockProvide.issueCreateUrl);
      expect(buttonEl.text()).toBe('Create new issue in Jira');
    });
  });
});
