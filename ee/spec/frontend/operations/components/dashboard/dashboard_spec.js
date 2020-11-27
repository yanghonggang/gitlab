import { GlEmptyState } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';
import Dashboard from 'ee/operations/components/dashboard/dashboard.vue';
import Project from 'ee/operations/components/dashboard/project.vue';
import createStore from 'ee/vue_shared/dashboards/store';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { mockProjectData, mockText } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('dashboard component', () => {
  const mockAddEndpoint = 'mock-addPath';
  const mockListEndpoint = 'mock-listPath';
  const store = createStore();
  let wrapper;
  let mockAxios;

  const emptyDashboardHelpPath = '/help/user/operations_dashboard/index.html';
  const emptyDashboardSvgPath = '/assets/illustrations/operations-dashboard_empty.svg';

  const mountComponent = ({ stubs = {}, state = {} } = {}) =>
    mount(Dashboard, {
      store,
      localVue,
      propsData: {
        addPath: mockAddEndpoint,
        listPath: mockListEndpoint,
        emptyDashboardSvgPath,
        emptyDashboardHelpPath,
      },
      state,
      stubs,
    });

  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findAddProjectButton = () => wrapper.find('[data-testid=add-projects-button]');

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: mockProjectData(1) });
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  it('renders dashboard title', () => {
    const dashboardTitle = wrapper.element.querySelector('.js-dashboard-title');

    expect(dashboardTitle.innerText.trim()).toEqual(mockText.DASHBOARD_TITLE);
  });

  describe('add projects button', () => {
    let button;

    beforeEach(() => {
      button = findAddProjectButton();
    });

    it('renders add projects text', () => {
      expect(button.text()).toBe(mockText.ADD_PROJECTS);
    });

    describe('when a project is added', () => {
      it('immediately requests the project list again', () => {
        mockAxios.reset();
        mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: mockProjectData(2) });
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [1], invalid: [] });

        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.projectClicked({ id: 1 });
          })
          .then(waitForPromises)
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(waitForPromises)
          .then(() => {
            expect(store.state.projects.length).toEqual(2);
            expect(wrapper.findAll(Project).length).toEqual(2);
          });
      });
    });
  });

  describe('wrapped components', () => {
    describe('dashboard project component', () => {
      const projectCount = 1;

      beforeEach(() => {
        const projects = mockProjectData(projectCount);
        store.state.projects = projects;
        wrapper = mountComponent();
      });

      it('includes a dashboard project component for each project', () => {
        const projectComponents = wrapper.findAll(Project);

        expect(projectComponents).toHaveLength(projectCount);
      });

      it('passes each project to the dashboard project component', () => {
        const [oneProject] = store.state.projects;
        const projectComponent = wrapper.find(Project);

        expect(projectComponent.props().project).toEqual(oneProject);
      });

      it('dispatches setProjects when projects changes', () => {
        const dispatch = jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation(() => {});
        const projects = mockProjectData(3);

        wrapper.vm.projects = projects;

        expect(dispatch).toHaveBeenCalledWith('setProjects', projects);
      });

      describe('when a project is removed', () => {
        it('immediately requests the project list again', () => {
          mockAxios.reset();
          mockAxios.onDelete(store.state.projects[0].remove_path).reply(200);
          mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: [] });

          wrapper.find('button.js-remove-button').vm.$emit('click');

          return waitForPromises().then(() => {
            expect(store.state.projects.length).toEqual(0);
            expect(wrapper.findAll(Project).length).toEqual(0);
          });
        });
      });
    });

    describe('add projects modal', () => {
      beforeEach(() => {
        store.state.projectSearchResults = mockProjectData(2);
        store.state.selectedProjects = mockProjectData(1);
      });

      it('clears state when adding a valid project', () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [1], invalid: [] });

        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(waitForPromises)
          .then(() => {
            expect(store.state.projectSearchResults).toHaveLength(0);
            expect(store.state.selectedProjects).toHaveLength(0);
          });
      });

      it('clears state when adding an invalid project', () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [], invalid: [1] });

        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(waitForPromises)
          .then(() => {
            expect(store.state.projectSearchResults).toHaveLength(0);
            expect(store.state.selectedProjects).toHaveLength(0);
          });
      });

      it('clears state when canceled', () => {
        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onCancel();
          })
          .then(waitForPromises)
          .then(() => {
            expect(store.state.projectSearchResults).toHaveLength(0);
            expect(store.state.selectedProjects).toHaveLength(0);
          });
      });

      it('clears state on error', () => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(500, {});

        return wrapper.vm
          .$nextTick()
          .then(() => {
            expect(store.state.projectSearchResults.length).not.toBe(0);
            expect(store.state.selectedProjects.length).not.toBe(0);
            wrapper.vm.onOk();
          })
          .then(waitForPromises)
          .then(() => {
            expect(store.state.projectSearchResults).toHaveLength(0);
            expect(store.state.selectedProjects).toHaveLength(0);
          });
      });
    });

    describe('when no projects have been added', () => {
      beforeEach(() => {
        store.state.projects = [];
        store.state.isLoadingProjects = false;
      });

      it('should render the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should link to the documentation', () => {
        const link = findEmptyState().find('[data-testid="documentation-link"]');

        expect(link.exists()).toBe(true);
        expect(link.attributes().href).toEqual(emptyDashboardHelpPath);
      });

      it('should render the add projects button', () => {
        const button = findAddProjectButton();

        expect(button.exists()).toBe(true);
        expect(button.text()).toEqual('Add projects');
      });
    });
  });
});
