import { merge } from 'lodash';
import { mount, shallowMount, createWrapper } from '@vue/test-utils';
import { within } from '@testing-library/dom';
import { GlModal } from '@gitlab/ui';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import DastProfilesList from 'ee/security_configuration/dast_profiles/components/dast_profiles_list.vue';

const TEST_ERROR_MESSAGE = 'something went wrong';

describe('EE - DastProfilesList', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = {
      profiles: [],
      fields: ['profileName', 'targetUrl', 'validationStatus'],
      hasMorePages: false,
      profilesPerPage: 10,
      errorMessage: '',
      errorDetails: [],
    };

    wrapper = mountFn(
      DastProfilesList,
      merge(
        {},
        {
          propsData: defaultProps,
        },
        options,
        {
          directives: {
            GlTooltip: createMockDirective(),
          },
        },
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mount);

  const withinComponent = () => within(wrapper.element);
  const getTable = () => withinComponent().getByRole('table', { name: /site profiles/i });
  const getAllRowGroups = () => within(getTable()).getAllByRole('rowgroup');
  const getTableBody = () => {
    // first item is the table head
    const [, tableBody] = getAllRowGroups();
    return tableBody;
  };
  const getAllTableRows = () => within(getTableBody()).getAllByRole('row');
  const getLoadMoreButton = () => wrapper.find('[data-testid="loadMore"]');
  const getAllLoadingIndicators = () => withinComponent().queryAllByTestId('loadingIndicator');
  const getErrorMessage = () => withinComponent().queryByText(TEST_ERROR_MESSAGE);
  const getErrorDetails = () => withinComponent().queryByRole('list', { name: /error details/i });
  const getDeleteButtonWithin = element =>
    createWrapper(within(element).queryByRole('button', { name: /delete/i }));
  const getModal = () => wrapper.find(GlModal);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    const profilesPerPage = 10;

    describe('initial load', () => {
      beforeEach(() => {
        createFullComponent({ propsData: { isLoading: true, profilesPerPage } });
      });

      it('shows a loading indicator for each profile item', () => {
        expect(getAllLoadingIndicators()).toHaveLength(profilesPerPage);
      });
    });

    describe('with profiles and more to load', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            isLoading: true,
            profilesPerPage,
            profiles: [{}],
            hasMoreProfilesToLoad: true,
          },
        });
      });

      it('does not show a loading indicator for each profile item', () => {
        expect(getAllLoadingIndicators()).toHaveLength(0);
      });

      it('sets the the "load more" button into a loading state', () => {
        expect(getLoadMoreButton().props('loading')).toBe(true);
      });
    });
  });

  describe('with no existing profiles', () => {
    it('shows a message to indicate that no profiles exist', () => {
      createComponent();

      const emptyStateMessage = withinComponent().getByText(/no profiles created yet/i);

      expect(emptyStateMessage).not.toBe(null);
    });
  });

  describe('with existing profiles', () => {
    const profiles = [
      {
        id: 1,
        profileName: 'Profile 1',
        targetUrl: 'http://example-1.com',
        editPath: '/1/edit',
        validationStatus: 'Pending',
      },
      {
        id: 2,
        profileName: 'Profile 2',
        targetUrl: 'http://example-2.com',
        editPath: '/2/edit',
        validationStatus: 'Pending',
      },
      {
        id: 3,
        profileName: 'Profile 2',
        targetUrl: 'http://example-2.com',
        editPath: '/3/edit',
        validationStatus: 'Pending',
      },
    ];

    const getTableRowForProfile = profile => getAllTableRows()[profiles.indexOf(profile)];

    describe('profiles list', () => {
      beforeEach(() => {
        createFullComponent({ propsData: { profiles } });
      });

      it('does not show loading indicators', () => {
        expect(getAllLoadingIndicators()).toHaveLength(0);
      });

      it('renders a list of profiles', () => {
        expect(getTable()).not.toBe(null);
        expect(getAllTableRows()).toHaveLength(profiles.length);
      });

      it.each(profiles)('renders list item %# correctly', profile => {
        const [
          profileCell,
          targetUrlCell,
          validationStatusCell,
          actionsCell,
        ] = getTableRowForProfile(profile).cells;

        expect(profileCell.innerText).toContain(profile.profileName);
        expect(targetUrlCell.innerText).toContain(profile.targetUrl);
        expect(validationStatusCell.innerText).toContain(profile.validationStatus);
        expect(within(actionsCell).getByRole('button', { name: /delete/i })).not.toBe(null);

        const editLink = within(actionsCell).getByRole('link', { name: /edit/i });
        expect(editLink).not.toBe(null);
        expect(editLink.getAttribute('href')).toBe(profile.editPath);
      });
    });

    describe('load more profiles', () => {
      it('does not show that there are more projects to be loaded per default', () => {
        createComponent({ propsData: { profiles } });

        expect(getLoadMoreButton().exists()).toBe(false);
      });

      describe('with more profiles', () => {
        beforeEach(() => {
          createFullComponent({ propsData: { profiles, hasMoreProfilesToLoad: true } });
        });

        it('shows that there are more projects to be loaded', () => {
          expect(getLoadMoreButton().exists()).toBe(true);
        });

        it('emits "load-more-profiles" when the load-more button is clicked', async () => {
          expect(wrapper.emitted('load-more-profiles')).toBe(undefined);

          await getLoadMoreButton().trigger('click');

          expect(wrapper.emitted('load-more-profiles')).toEqual(expect.any(Array));
        });
      });
    });

    describe.each(profiles)('delete profile', profile => {
      beforeEach(() => {
        createFullComponent({ propsData: { profiles } });
      });

      const getCurrentProfileDeleteButton = () =>
        getDeleteButtonWithin(getTableRowForProfile(profile));

      it('shows a tooltip on the delete button', () => {
        expect(getBinding(getCurrentProfileDeleteButton().element, 'gl-tooltip')).not.toBe(
          undefined,
        );
        expect(getCurrentProfileDeleteButton().attributes().title).toBe('Delete profile');
      });

      it('opens a modal with the correct title when a delete button is clicked', async () => {
        expect(getModal().html()).toBe('');

        getCurrentProfileDeleteButton().trigger('click');

        await wrapper.vm.$nextTick();

        expect(
          within(getModal().element).getByText(/are you sure you want to delete this profile/i),
        ).not.toBe(null);
      });

      it(`emits "@deleteProfile" with the right payload when the modal's primary action is triggered`, async () => {
        expect(wrapper.emitted('delete-profile')).toBe(undefined);

        getCurrentProfileDeleteButton().trigger('click');

        await wrapper.vm.$nextTick();

        getModal().vm.$emit('ok');

        expect(wrapper.emitted('delete-profile')[0]).toEqual([profile.id]);
      });
    });
  });

  describe('errors', () => {
    it('does not show an error message by default', () => {
      createFullComponent();

      expect(getErrorMessage()).toBe(null);
      expect(getErrorDetails()).toBe(null);
    });

    it('shows an error message and details', () => {
      const errorDetails = ['foo', 'bar'];
      createFullComponent({
        propsData: { errorMessage: TEST_ERROR_MESSAGE, errorDetails },
      });

      expect(getErrorMessage()).not.toBe(null);
      expect(getErrorDetails()).not.toBe(null);
      expect(within(getErrorDetails()).getByText(errorDetails[0])).not.toBe(null);
      expect(within(getErrorDetails()).getByText(errorDetails[1])).not.toBe(null);
    });
  });
});
