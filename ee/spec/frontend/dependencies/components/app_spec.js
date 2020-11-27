import { GlEmptyState, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import DependenciesApp from 'ee/dependencies/components/app.vue';
import DependenciesActions from 'ee/dependencies/components/dependencies_actions.vue';
import DependencyListIncompleteAlert from 'ee/dependencies/components/dependency_list_incomplete_alert.vue';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';
import PaginatedDependenciesTable from 'ee/dependencies/components/paginated_dependencies_table.vue';
import createStore from 'ee/dependencies/store';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import { REPORT_STATUS } from 'ee/dependencies/store/modules/list/constants';
import { TEST_HOST } from 'helpers/test_constants';
import { getDateInPast } from '~/lib/utils/datetime_utility';

describe('DependenciesApp component', () => {
  let store;
  let wrapper;
  const { namespace: allNamespace } = DEPENDENCY_LIST_TYPES.all;

  const basicAppProps = {
    endpoint: '/foo',
    emptyStateSvgPath: '/bar.svg',
    documentationPath: TEST_HOST,
    supportDocumentationPath: `${TEST_HOST}/dependency_scanning#supported-languages`,
  };

  const factory = ({ props = basicAppProps, ...options } = {}) => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockImplementation();

    const stubs = Object.keys(DependenciesApp.components).filter(name => name !== 'GlSprintf');

    wrapper = mount(DependenciesApp, {
      store,
      propsData: { ...props },
      stubs,
      ...options,
    });
  };

  const setStateJobNotRun = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [],
    });
    store.state[allNamespace].pageInfo.total = 0;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.jobNotSetUp;
  };

  const setStateLoaded = () => {
    const total = 2;
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: Array(total)
        .fill(null)
        .map((_, id) => ({ id })),
    });
    store.state[allNamespace].pageInfo.total = total;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.ok;
    store.state[allNamespace].reportInfo.generatedAt = getDateInPast(new Date(), 7);
    store.state[allNamespace].reportInfo.jobPath = '/jobs/foo/321';
  };

  const setStateJobFailed = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [],
    });
    store.state[allNamespace].pageInfo.total = 0;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.jobFailed;
    store.state[allNamespace].reportInfo.jobPath = '/jobs/foo/321';
  };

  const setStateListIncomplete = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [{ id: 0 }],
    });
    store.state[allNamespace].pageInfo.total = 1;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.incomplete;
  };

  const setStateNoDependencies = () => {
    Object.assign(store.state[allNamespace], {
      initialized: true,
      isLoading: false,
      dependencies: [],
    });
    store.state[allNamespace].pageInfo.total = 0;
    store.state[allNamespace].reportInfo.status = REPORT_STATUS.noDependencies;
  };

  const findJobFailedAlert = () => wrapper.find(DependencyListJobFailedAlert);
  const findIncompleteListAlert = () => wrapper.find(DependencyListIncompleteAlert);
  const findDependenciesTables = () => wrapper.findAll(PaginatedDependenciesTable);

  const findHeader = () => wrapper.find('section > header');
  const findHeaderHelpLink = () => findHeader().find(GlLink);
  const findHeaderJobLink = () => wrapper.find({ ref: 'jobLink' });

  const expectComponentWithProps = (Component, props = {}) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.isVisible()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  const expectComponentPropsToMatchSnapshot = Component => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.props()).toMatchSnapshot();
  };

  const expectNoDependenciesTables = () => expect(findDependenciesTables()).toHaveLength(0);
  const expectNoHeader = () => expect(findHeader().exists()).toBe(false);

  const expectDependenciesTable = () => {
    const tables = findDependenciesTables();
    expect(tables).toHaveLength(1);
    expect(tables.at(0).props()).toEqual({ namespace: allNamespace });
  };

  const expectHeader = () => {
    expect(findHeader().exists()).toBe(true);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the correct initial actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        ['setDependenciesEndpoint', basicAppProps.endpoint],
        ['fetchDependencies'],
      ]);
    });

    it('shows only the loading icon', () => {
      expectComponentWithProps(GlLoadingIcon);
      expectNoHeader();
      expectNoDependenciesTables();
    });

    describe('given the dependency list job has not yet run', () => {
      beforeEach(() => {
        setStateJobNotRun();

        return wrapper.vm.$nextTick();
      });

      it('shows only the empty state', () => {
        expectComponentWithProps(GlEmptyState, { svgPath: basicAppProps.emptyStateSvgPath });
        expectComponentPropsToMatchSnapshot(GlEmptyState);
        expectNoHeader();
        expectNoDependenciesTables();
      });
    });

    describe('given a list of dependencies and ok report', () => {
      beforeEach(() => {
        setStateLoaded();

        return wrapper.vm.$nextTick();
      });

      it('shows the dependencies table with the correct props', () => {
        expectHeader();
        expectDependenciesTable();
      });

      it('shows a link to the latest job', () => {
        expect(findHeaderJobLink().attributes('href')).toBe('/jobs/foo/321');
      });

      it('shows when the last job ran', () => {
        expect(findHeader().text()).toContain('1 week ago');
      });

      it('shows a link to the dependencies documentation page', () => {
        expect(findHeaderHelpLink().attributes('href')).toBe(TEST_HOST);
      });

      it('passes the correct namespace to dependencies actions component', () => {
        expectComponentWithProps(DependenciesActions, { namespace: allNamespace });
      });

      describe('given the user has public permissions', () => {
        beforeEach(() => {
          store.state[allNamespace].reportInfo.generatedAt = '';
          store.state[allNamespace].reportInfo.jobPath = '';

          return wrapper.vm.$nextTick();
        });

        it('shows the header', () => {
          expectHeader();
        });

        it('does not show when the last job ran', () => {
          expect(findHeader().text()).not.toContain('1 week ago');
        });

        it('does not show a link to the latest job', () => {
          expect(findHeaderJobLink().exists()).toBe(false);
        });
      });
    });

    describe('given the dependency list job failed', () => {
      beforeEach(() => {
        setStateJobFailed();

        return wrapper.vm.$nextTick();
      });

      it('passes the correct props to the job failure alert', () => {
        expectComponentWithProps(DependencyListJobFailedAlert, {
          jobPath: '/jobs/foo/321',
        });
      });

      it('shows the dependencies table with the correct props', expectDependenciesTable);

      describe('when the job failure alert emits the dismiss event', () => {
        beforeEach(() => {
          const alertWrapper = findJobFailedAlert();
          alertWrapper.vm.$emit('dismiss');
          return wrapper.vm.$nextTick();
        });

        it('does not render the job failure alert', () => {
          expect(findJobFailedAlert().exists()).toBe(false);
        });
      });
    });

    describe('given a dependency list which is known to be incomplete', () => {
      beforeEach(() => {
        setStateListIncomplete();

        return wrapper.vm.$nextTick();
      });

      it('passes the correct props to the incomplete-list alert', () => {
        expectComponentWithProps(DependencyListIncompleteAlert);
      });

      it('shows the dependencies table with the correct props', expectDependenciesTable);

      describe('when the incomplete-list alert emits the dismiss event', () => {
        beforeEach(() => {
          const alertWrapper = findIncompleteListAlert();
          alertWrapper.vm.$emit('dismiss');
          return wrapper.vm.$nextTick();
        });

        it('does not render the incomplete-list alert', () => {
          expect(findIncompleteListAlert().exists()).toBe(false);
        });
      });
    });

    describe('given there are no dependencies detected', () => {
      beforeEach(() => {
        setStateNoDependencies();
      });

      it('shows only the empty state', () => {
        expectComponentWithProps(GlEmptyState, { svgPath: basicAppProps.emptyStateSvgPath });
        expectComponentPropsToMatchSnapshot(GlEmptyState);
        expectNoHeader();
        expectNoDependenciesTables();
      });
    });
  });
});
