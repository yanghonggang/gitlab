import { GlEmptyState } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import PipelineSecurityDashboard from 'ee/security_dashboard/components/pipeline_security_dashboard.vue';
import SecurityDashboard from 'ee/security_dashboard/components/security_dashboard_vuex.vue';
import SecurityReportsSummary from 'ee/security_dashboard/components/security_reports_summary.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const dashboardDocumentation = '/help/docs';
const emptyStateSvgPath = '/svgs/empty/svg';
const pipelineId = 1234;
const pipelineIid = 4321;
const projectId = 5678;
const sourceBranch = 'feature-branch-1';
const vulnerabilitiesEndpoint = '/vulnerabilities';
const loadingErrorIllustrations = {
  401: '/401.svg',
  403: '/403.svg',
};

describe('Pipeline Security Dashboard component', () => {
  let store;
  let wrapper;

  const factory = options => {
    store = new Vuex.Store({
      modules: {
        vulnerabilities: {
          namespaced: true,
          actions: {
            setSourceBranch() {},
          },
        },
        pipelineJobs: {
          namespaced: true,
          actions: {
            setPipelineJobsPath() {},
            setProjectId() {},
          },
        },
      },
    });
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(PipelineSecurityDashboard, {
      localVue,
      store,
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        pipelineId,
        pipelineIid,
        projectId,
        sourceBranch,
        vulnerabilitiesEndpoint,
        loadingErrorIllustrations,
      },
      ...options,
      data() {
        return {
          securityReportSummary: {},
          ...options?.data,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the expected actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['vulnerabilities/setSourceBranch', sourceBranch],
        ['pipelineJobs/setPipelineJobsPath', ''],
        ['pipelineJobs/setProjectId', 5678],
      ]);
    });

    it('renders the security dashboard', () => {
      const dashboard = wrapper.find(SecurityDashboard);
      expect(dashboard.exists()).toBe(true);
      expect(dashboard.props()).toMatchObject({
        pipelineId,
        vulnerabilitiesEndpoint,
      });
    });
  });

  describe('with a stubbed dashboard for slot testing', () => {
    beforeEach(() => {
      factory({
        stubs: {
          'security-dashboard': { template: '<div><slot name="empty-state"></slot></div>' },
        },
      });
    });

    it('renders empty state component with correct props', () => {
      const emptyState = wrapper.find(GlEmptyState);

      expect(emptyState.props()).toMatchObject({
        svgPath: '/svgs/empty/svg',
        title: 'No vulnerabilities found for this pipeline',
        description: `While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
        primaryButtonLink: '/help/docs',
        primaryButtonText: 'Learn more about setting up your dashboard',
      });
    });
  });

  describe('security reports summary', () => {
    const securityReportSummary = {
      dast: {
        vulnerabilitiesCount: 123,
      },
    };

    it('shows the summary if it is non-empty', () => {
      factory({
        data: {
          securityReportSummary,
        },
      });
      expect(wrapper.find(SecurityReportsSummary).exists()).toBe(true);
    });

    it('does not show the summary if it is empty', () => {
      factory({
        data: {
          securityReportSummary: null,
        },
      });
      expect(wrapper.find(SecurityReportsSummary).exists()).toBe(false);
    });
  });
});
