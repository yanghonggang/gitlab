import { GlAlert, GlLoadingIcon, GlTable, GlIcon, GlAvatarsInline, GlPagination } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import ThroughputTable from 'ee/analytics/merge_request_analytics/components/throughput_table.vue';
import {
  THROUGHPUT_TABLE_STRINGS,
  THROUGHPUT_TABLE_TEST_IDS as TEST_IDS,
} from 'ee/analytics/merge_request_analytics/constants';
import store from 'ee/analytics/merge_request_analytics/store';
import {
  throughputTableData,
  startDate,
  endDate,
  fullPath,
  throughputTableHeaders,
  pageInfo,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const defaultQueryVariables = {
  assigneeUsername: null,
  authorUsername: null,
  milestoneTitle: null,
  labels: null,
};

const defaultMocks = {
  $apollo: {
    queries: {
      throughputTableData: {},
    },
  },
};

describe('ThroughputTable', () => {
  let wrapper;

  function createComponent(options = {}) {
    const { mocks = defaultMocks, func = shallowMount } = options;
    return func(ThroughputTable, {
      localVue,
      store,
      mocks,
      provide: {
        fullPath,
      },
      props: {
        startDate,
        endDate,
      },
    });
  }

  const displaysComponent = (component, visible) => {
    expect(wrapper.find(component).exists()).toBe(visible);
  };

  const additionalData = data => {
    wrapper.setData({
      throughputTableData: {
        list: [{ ...throughputTableData[0], ...data }],
        pageInfo,
      },
    });
  };

  const findTable = () => wrapper.find(GlTable);

  const findCol = testId => findTable().find(`[data-testid="${testId}"]`);

  const findColSubItem = (colTestId, childTetestId) =>
    findCol(colTestId).find(`[data-testid="${childTetestId}"]`);

  const findColSubComponent = (colTestId, childComponent) =>
    findCol(colTestId).find(childComponent);

  const findPagination = () => wrapper.find(GlPagination);

  const findPrevious = () =>
    findPagination()
      .findAll('.page-item')
      .at(0);

  const findNext = () =>
    findPagination()
      .findAll('.page-item')
      .at(1);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays an empty state message when there is no data', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_TABLE_STRINGS.NO_DATA);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });

    it('does not display the pagination', () => {
      displaysComponent(GlPagination, false);
    });
  });

  describe('while loading', () => {
    const apolloLoading = {
      queries: {
        throughputTableData: {
          loading: true,
        },
      },
    };

    beforeEach(() => {
      wrapper = createComponent({ mocks: { ...defaultMocks, $apollo: apolloLoading } });
    });

    it('displays a loading icon', () => {
      displaysComponent(GlLoadingIcon, true);
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });

    it('does not display the no data message', () => {
      displaysComponent(GlAlert, false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent({ func: mount });
      wrapper.setData({
        throughputTableData: {
          list: throughputTableData,
          pageInfo,
        },
      });
    });

    it('displays the table', () => {
      displaysComponent(GlTable, true);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('does not display the no data message', () => {
      displaysComponent(GlAlert, false);
    });

    it('displays the pagination', () => {
      displaysComponent(GlPagination, true);
    });

    describe('table fields', () => {
      it('displays the correct table headers', () => {
        const headers = findTable().findAll(`[data-testid="${TEST_IDS.TABLE_HEADERS}"]`);

        expect(headers).toHaveLength(throughputTableHeaders.length);

        throughputTableHeaders.forEach((headerText, i) =>
          expect(headers.at(i).text()).toEqual(headerText),
        );
      });

      describe('displays the correct merge request details', () => {
        it('includes the correct title and IID', () => {
          const { title, iid } = throughputTableData[0];

          expect(findCol(TEST_IDS.MERGE_REQUEST_DETAILS).text()).toContain(`${title} !${iid}`);
        });

        it('includes an inactive label icon by default', () => {
          const labels = findColSubItem(TEST_IDS.MERGE_REQUEST_DETAILS, TEST_IDS.LABEL_DETAILS);
          const icon = labels.find(GlIcon);

          expect(labels.text()).toBe('0');
          expect(labels.classes()).toContain('gl-opacity-5');
          expect(icon.exists()).toBe(true);
          expect(icon.props('name')).toBe('label');
        });

        it('includes an inactive comment icon by default', () => {
          const commentCount = findColSubItem(
            TEST_IDS.MERGE_REQUEST_DETAILS,
            TEST_IDS.COMMENT_COUNT,
          );
          const icon = commentCount.find(GlIcon);

          expect(commentCount.text()).toBe('0');
          expect(commentCount.classes()).toContain('gl-opacity-5');
          expect(icon.exists()).toBe(true);
          expect(icon.props('name')).toBe('comments');
        });

        it('includes an active label icon and count when available', async () => {
          additionalData({
            labels: {
              count: 1,
            },
          });

          await wrapper.vm.$nextTick();

          const labelDetails = findColSubItem(
            TEST_IDS.MERGE_REQUEST_DETAILS,
            TEST_IDS.LABEL_DETAILS,
          );
          const icon = labelDetails.find(GlIcon);

          expect(labelDetails.text()).toBe('1');
          expect(labelDetails.classes()).not.toContain('gl-opacity-5');
          expect(icon.exists()).toBe(true);
          expect(icon.props('name')).toBe('label');
        });

        it('includes an active comment icon and count when available', async () => {
          additionalData({
            userNotesCount: 2,
          });

          await wrapper.vm.$nextTick();

          const commentCount = findColSubItem(
            TEST_IDS.MERGE_REQUEST_DETAILS,
            TEST_IDS.COMMENT_COUNT,
          );
          const icon = commentCount.find(GlIcon);

          expect(commentCount.text()).toBe('2');
          expect(commentCount.classes()).not.toContain('gl-opacity-5');
          expect(icon.exists()).toBe(true);
          expect(icon.props('name')).toBe('comments');
        });

        it('includes a pipeline icon when available', async () => {
          const iconName = 'status_canceled';

          additionalData({
            pipelines: {
              nodes: [
                {
                  detailedStatus: { icon: iconName },
                },
              ],
            },
          });

          await wrapper.vm.$nextTick();

          const icon = findColSubComponent(TEST_IDS.MERGE_REQUEST_DETAILS, GlIcon);

          expect(icon.find(GlIcon).exists()).toBe(true);
          expect(icon.props('name')).toBe(iconName);
        });

        describe('approval details', () => {
          const iconName = 'approval';

          it('does not display by default', async () => {
            const approved = findColSubItem(TEST_IDS.MERGE_REQUEST_DETAILS, TEST_IDS.APPROVED);

            expect(approved.exists()).toBe(false);
          });

          it('displays the singular when there is a single approval', async () => {
            additionalData({
              approvedBy: {
                nodes: [
                  {
                    id: 1,
                  },
                ],
              },
            });

            await wrapper.vm.$nextTick();

            const approved = findColSubItem(TEST_IDS.MERGE_REQUEST_DETAILS, TEST_IDS.APPROVED);
            const icon = approved.find(GlIcon);

            expect(approved.text()).toBe('1 Approval');
            expect(icon.exists()).toBe(true);
            expect(icon.props('name')).toBe(iconName);
          });

          it('displays the plural when there are multiple approvals', async () => {
            additionalData({
              approvedBy: {
                nodes: [
                  {
                    id: 1,
                  },
                  {
                    id: 2,
                  },
                ],
              },
            });

            await wrapper.vm.$nextTick();

            const approved = findColSubItem(TEST_IDS.MERGE_REQUEST_DETAILS, TEST_IDS.APPROVED);
            const icon = approved.find(GlIcon);

            expect(approved.text()).toBe('2 Approvals');
            expect(icon.exists()).toBe(true);
            expect(icon.props('name')).toBe(iconName);
          });
        });
      });

      it('displays the correct date merged', () => {
        expect(findCol(TEST_IDS.DATE_MERGED).text()).toBe('2020-08-06');
      });

      it('displays the correct time to merge', () => {
        expect(findCol(TEST_IDS.TIME_TO_MERGE).text()).toBe('4 minutes');
      });

      it('does not display a milestone if not present', () => {
        expect(findCol(TEST_IDS.MILESTONE).exists()).toBe(false);
      });

      it('displays the correct milestone when available', async () => {
        const title = 'v1.0';

        additionalData({
          milestone: { title },
        });

        await wrapper.vm.$nextTick();

        expect(findCol(TEST_IDS.MILESTONE).text()).toBe(title);
      });

      it('displays the correct commit count', () => {
        expect(findCol(TEST_IDS.COMMITS).text()).toBe('1');
      });

      it('displays the correct pipeline count', () => {
        expect(findCol(TEST_IDS.PIPELINES).text()).toBe('0');
      });

      it('displays the correctly formatted line changes', () => {
        expect(findCol(TEST_IDS.LINE_CHANGES).text()).toBe('+2 -1');
      });

      it('displays the correct assignees data', () => {
        const assignees = findColSubComponent(TEST_IDS.ASSIGNEES, GlAvatarsInline);

        expect(assignees.exists()).toBe(true);
        expect(assignees.props('avatars')).toBe(throughputTableData[0].assignees.nodes);
      });
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      wrapper = createComponent({ func: mount });
      wrapper.setData({
        throughputTableData: {
          list: throughputTableData,
          pageInfo,
        },
      });
    });

    it('disables the prev button on the first page', () => {
      expect(findPrevious().classes()).toContain('disabled');
      expect(findNext().classes()).not.toContain('disabled');
    });

    it('disables the next button on the last page', async () => {
      wrapper.setData({
        pagination: {
          currentPage: 3,
        },
        throughputTableData: {
          pageInfo: {
            hasNextPage: false,
          },
        },
      });

      await wrapper.vm.$nextTick();

      expect(findPrevious().classes()).not.toContain('disabled');
      expect(findNext().classes()).toContain('disabled');
    });

    it('shows the prev and next buttons on middle pages', async () => {
      wrapper.setData({
        pagination: {
          currentPage: 2,
        },
        throughputTableData: {
          pageInfo: {
            hasNextPage: true,
            hasPrevPage: true,
          },
        },
      });

      await wrapper.vm.$nextTick();

      expect(findPrevious().classes()).not.toContain('disabled');
      expect(findNext().classes()).not.toContain('disabled');
    });
  });

  describe('with errors', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.setData({ hasError: true });
    });

    it('does not display the table', () => {
      displaysComponent(GlTable, false);
    });

    it('does not display a loading icon', () => {
      displaysComponent(GlLoadingIcon, false);
    });

    it('displays an error message', () => {
      const alert = wrapper.find(GlAlert);

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(THROUGHPUT_TABLE_STRINGS.ERROR_FETCHING_DATA);
    });
  });

  describe('when fetching data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has initial variables set', () => {
      expect(
        wrapper.vm.$options.apollo.throughputTableData.variables.bind(wrapper.vm)(),
      ).toMatchObject(defaultQueryVariables);
    });

    it('gets filter variables from store', async () => {
      const operator = '=';
      const assigneeUsername = 'foo';
      const authorUsername = 'bar';
      const milestoneTitle = 'baz';
      const labels = ['quis', 'quux'];

      wrapper.vm.$store.dispatch('filters/initialize', {
        selectedAssignee: { value: assigneeUsername, operator },
        selectedAuthor: { value: authorUsername, operator },
        selectedMilestone: { value: milestoneTitle, operator },
        selectedLabelList: [{ value: labels[0], operator }, { value: labels[1], operator }],
      });
      await wrapper.vm.$nextTick();
      expect(
        wrapper.vm.$options.apollo.throughputTableData.variables.bind(wrapper.vm)(),
      ).toMatchObject({
        assigneeUsername,
        authorUsername,
        milestoneTitle,
        labels,
      });
    });
  });
});
