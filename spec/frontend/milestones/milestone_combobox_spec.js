import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { GlLoadingIcon, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ENTER_KEY } from '~/lib/utils/keys';
import MilestoneCombobox from '~/milestones/components/milestone_combobox.vue';
import { milestones as projectMilestones } from './mock_data';
import createStore from '~/milestones/stores/';

const extraLinks = [
  { text: 'Create new', url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/-/milestones/new' },
  { text: 'Manage milestones', url: '/h5bp/html5-boilerplate/-/milestones' },
];

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Milestone combobox component', () => {
  const projectId = '8';
  const X_TOTAL_HEADER = 'x-total';

  let wrapper;
  let projectMilestonesApiCallSpy;
  let searchApiCallSpy;

  const createComponent = (props = {}, attrs = {}) => {
    wrapper = mount(MilestoneCombobox, {
      propsData: {
        projectId,
        extraLinks,
        value: [],
        ...props,
      },
      attrs,
      listeners: {
        // simulate a parent component v-model binding
        input: selectedMilestone => {
          wrapper.setProps({ value: selectedMilestone });
        },
      },
      stubs: {
        GlSearchBoxByType: true,
      },
      localVue,
      store: createStore(),
    });
  };

  beforeEach(() => {
    const mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    projectMilestonesApiCallSpy = jest
      .fn()
      .mockReturnValue([200, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    searchApiCallSpy = jest
      .fn()
      .mockReturnValue([200, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    mock
      .onGet(`/api/v4/projects/${projectId}/milestones`)
      .reply(config => projectMilestonesApiCallSpy(config));

    mock.onGet(`/api/v4/projects/${projectId}/search`).reply(config => searchApiCallSpy(config));
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  //
  // Finders
  //
  const findButtonContent = () => wrapper.find('[data-testid="milestone-combobox-button-content"]');

  const findNoResults = () => wrapper.find('[data-testid="milestone-combobox-no-results"]');

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const findSearchBox = () => wrapper.find(GlSearchBoxByType);

  const findProjectMilestonesSection = () =>
    wrapper.find('[data-testid="project-milestones-section"]');
  const findProjectMilestonesDropdownItems = () =>
    findProjectMilestonesSection().findAll(GlDropdownItem);
  const findFirstProjectMilestonesDropdownItem = () => findProjectMilestonesDropdownItems().at(0);

  //
  // Expecters
  //
  const projectMilestoneSectionContainsErrorMessage = () => {
    const projectMilestoneSection = findProjectMilestonesSection();

    return projectMilestoneSection
      .text()
      .includes(s__('MilestoneCombobox|An error occurred while searching for milestones'));
  };

  //
  // Convenience methods
  //
  const updateQuery = newQuery => {
    findSearchBox().vm.$emit('input', newQuery);
  };

  const selectFirstProjectMilestone = () => {
    findFirstProjectMilestonesDropdownItem().vm.$emit('click');
  };

  const waitForRequests = ({ andClearMocks } = { andClearMocks: false }) =>
    axios.waitForAll().then(() => {
      if (andClearMocks) {
        projectMilestonesApiCallSpy.mockClear();
      }
    });

  describe('initialization behavior', () => {
    beforeEach(createComponent);

    it('initializes the dropdown with project milestones when mounted', () => {
      return waitForRequests().then(() => {
        expect(projectMilestonesApiCallSpy).toHaveBeenCalledTimes(1);
      });
    });

    it('shows a spinner while network requests are in progress', () => {
      expect(findLoadingIcon().exists()).toBe(true);

      return waitForRequests().then(() => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    it('shows additional links', () => {
      const links = wrapper.findAll('[data-testid="milestone-combobox-extra-links"]');
      links.wrappers.forEach((item, idx) => {
        expect(item.text()).toBe(extraLinks[idx].text);
        expect(item.attributes('href')).toBe(extraLinks[idx].url);
      });
    });
  });

  describe('post-initialization behavior', () => {
    describe('when the parent component provides an `id` binding', () => {
      const id = '8';

      beforeEach(() => {
        createComponent({}, { id });

        return waitForRequests();
      });

      it('adds the provided ID to the GlDropdown instance', () => {
        expect(wrapper.attributes().id).toBe(id);
      });
    });

    describe('when milestones are pre-selected', () => {
      beforeEach(() => {
        createComponent({ value: projectMilestones });

        return waitForRequests();
      });

      it('renders the pre-selected project milestones', () => {
        expect(findButtonContent().text()).toBe('v0.1 + 5 more');
      });
    });

    describe('when the search query is updated', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the search when the search query is updated', () => {
        updateQuery('v1.2.3');

        return waitForRequests().then(() => {
          expect(searchApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when the Enter is pressed', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the search when Enter is pressed', () => {
        findSearchBox().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        return waitForRequests().then(() => {
          expect(searchApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when no results are found', () => {
      beforeEach(() => {
        projectMilestonesApiCallSpy = jest
          .fn()
          .mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

        createComponent();

        return waitForRequests();
      });

      describe('when the search query is empty', () => {
        it('renders a "no results" message', () => {
          expect(findNoResults().text()).toBe(s__('MilestoneCombobox|No matching results'));
        });
      });
    });

    describe('project milestones', () => {
      describe('when the project milestones search returns results', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(true);
        });

        it('renders the "Project milestones" heading with a total number indicator', () => {
          expect(
            findProjectMilestonesSection()
              .find('[data-testid="milestone-results-section-header"]')
              .text(),
          ).toBe('Project milestones  6');
        });

        it("does not render an error message in the project milestone section's body", () => {
          expect(projectMilestoneSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each project milestones as a selectable item', () => {
          const dropdownItems = findProjectMilestonesDropdownItems();

          projectMilestones.forEach((milestone, i) => {
            expect(dropdownItems.at(i).text()).toBe(milestone.title);
          });
        });
      });

      describe('when the project milestones search returns no results', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(false);
        });
      });

      describe('when the project milestones search returns an error', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest.fn().mockReturnValue([500]);
          searchApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent({ value: [] });

          return waitForRequests();
        });

        it('renders the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(true);
        });

        it("renders an error message in the project milestones section's body", () => {
          expect(projectMilestoneSectionContainsErrorMessage()).toBe(true);
        });
      });
    });

    describe('selection', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests();
      });

      it('renders a checkmark by the selected item', async () => {
        selectFirstProjectMilestone();

        await localVue.nextTick();

        expect(
          findFirstProjectMilestonesDropdownItem()
            .find('span')
            .classes('selected-item'),
        ).toBe(false);

        selectFirstProjectMilestone();

        return localVue.nextTick().then(() => {
          expect(
            findFirstProjectMilestonesDropdownItem()
              .find('span')
              .classes('selected-item'),
          ).toBe(true);
        });
      });

      describe('when a project milestones is selected', () => {
        beforeEach(() => {
          createComponent();
          projectMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([200, [{ title: 'v1.0' }], { [X_TOTAL_HEADER]: '1' }]);

          return waitForRequests();
        });

        it("displays the project milestones name in the dropdown's button", async () => {
          selectFirstProjectMilestone();
          await localVue.nextTick();

          expect(findButtonContent().text()).toBe(s__('MilestoneCombobox|No milestone'));

          selectFirstProjectMilestone();

          await localVue.nextTick();
          expect(findButtonContent().text()).toBe('v1.0');
        });

        it('updates the v-model binding with the project milestone title', () => {
          expect(wrapper.vm.value).toEqual([]);

          selectFirstProjectMilestone();

          expect(wrapper.vm.value).toEqual(['v1.0']);
        });
      });
    });
  });
});
