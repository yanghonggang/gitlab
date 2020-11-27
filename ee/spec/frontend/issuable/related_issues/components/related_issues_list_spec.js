import { mount } from '@vue/test-utils';
import IssueWeight from 'ee/boards/components/issue_card_weight.vue';
import { issuable1 } from 'jest/vue_shared/components/issue/related_issuable_mock_data';
import RelatedIssuesList from '~/related_issues/components/related_issues_list.vue';
import { PathIdSeparator } from '~/related_issues/constants';

/*
 * Here we only test the behavior of Related Issues with Weight, as weight is an EE-only feature.
 */
describe('RelatedIssuesList', () => {
  let wrapper;

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('related item contents', () => {
    beforeAll(() => {
      wrapper = mount(RelatedIssuesList, {
        propsData: {
          issuableType: 'issue',
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1],
        },
      });
    });

    it('shows weight', () => {
      expect(
        wrapper
          .find(IssueWeight)
          .find('.board-card-info-text')
          .text(),
      ).toBe(issuable1.weight.toString());
    });
  });
});
