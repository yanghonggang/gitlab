import { shallowMount } from '@vue/test-utils';
import { GlToggle, GlBadge } from '@gitlab/ui';
import { trimText } from 'helpers/text_helper';
import { mockTracking } from 'helpers/tracking_helper';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
  NEW_VERSION_FLAG,
  LEGACY_FLAG,
  DEFAULT_PERCENT_ROLLOUT,
} from '~/feature_flags/constants';
import FeatureFlagsTable from '~/feature_flags/components/feature_flags_table.vue';

const getDefaultProps = () => ({
  featureFlags: [
    {
      id: 1,
      iid: 1,
      active: true,
      name: 'flag name',
      description: 'flag description',
      destroy_path: 'destroy/path',
      edit_path: 'edit/path',
      version: LEGACY_FLAG,
      scopes: [
        {
          id: 1,
          active: true,
          environmentScope: 'scope',
          canUpdate: true,
          protected: false,
          rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
          rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
          shouldBeDestroyed: false,
        },
      ],
    },
  ],
});

describe('Feature flag table', () => {
  let wrapper;
  let props;

  const createWrapper = (propsData, opts = {}) => {
    wrapper = shallowMount(FeatureFlagsTable, {
      propsData,
      provide: {
        csrfToken: 'fakeToken',
      },
      ...opts,
    });
  };

  beforeEach(() => {
    props = getDefaultProps();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with an active scope and a standard rollout strategy', () => {
    beforeEach(() => {
      createWrapper(props);
    });

    it('Should render a table', () => {
      expect(wrapper.classes('table-holder')).toBe(true);
    });

    it('Should render rows', () => {
      expect(wrapper.find('.gl-responsive-table-row').exists()).toBe(true);
    });

    it('should render an ID column', () => {
      expect(wrapper.find('.js-feature-flag-id').exists()).toBe(true);
      expect(trimText(wrapper.find('.js-feature-flag-id').text())).toEqual('^1');
    });

    it('Should render a status column', () => {
      const badge = wrapper.find('[data-testid="feature-flag-status-badge"]');

      expect(badge.exists()).toBe(true);
      expect(trimText(badge.text())).toEqual('Active');
    });

    it('Should render a feature flag column', () => {
      expect(wrapper.find('.js-feature-flag-title').exists()).toBe(true);
      expect(trimText(wrapper.find('.feature-flag-name').text())).toEqual('flag name');

      expect(trimText(wrapper.find('.feature-flag-description').text())).toEqual(
        'flag description',
      );
    });

    it('should render an environments specs column', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(envColumn).toBeDefined();
      expect(trimText(envColumn.text())).toBe('scope');
    });

    it('should render an environments specs badge with active class', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find(GlBadge).text())).toBe('scope');
    });

    it('should render an actions column', () => {
      expect(wrapper.find('.table-action-buttons').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-delete-button').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-edit-button').exists()).toBe(true);
      expect(wrapper.find('.js-feature-flag-edit-button').attributes('href')).toEqual('edit/path');
    });
  });

  describe('when active and with an update toggle', () => {
    let toggle;
    let spy;

    beforeEach(() => {
      props.featureFlags[0].update_path = props.featureFlags[0].destroy_path;
      createWrapper(props);
      toggle = wrapper.find(GlToggle);
      spy = mockTracking('_category_', toggle.element, jest.spyOn);
    });

    it('should have a toggle', () => {
      expect(toggle.exists()).toBe(true);
      expect(toggle.props('value')).toBe(true);
    });

    it('should trigger a toggle event', () => {
      toggle.vm.$emit('change');
      const flag = { ...props.featureFlags[0], active: !props.featureFlags[0].active };

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('toggle-flag')).toEqual([[flag]]);
      });
    });

    it('should track a click', () => {
      toggle.trigger('click');

      expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'feature_flag_toggle',
      });
    });
  });

  describe('with an active scope and a percentage rollout strategy', () => {
    beforeEach(() => {
      props.featureFlags[0].scopes[0].rolloutStrategy = ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
      props.featureFlags[0].scopes[0].rolloutPercentage = '54';
      createWrapper(props);
    });

    it('should render an environments specs badge with percentage', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find(GlBadge).text())).toBe('scope: 54%');
    });
  });

  describe('with an inactive scope', () => {
    beforeEach(() => {
      props.featureFlags[0].scopes[0].active = false;
      createWrapper(props);
    });

    it('should render an environments specs badge with inactive class', () => {
      const envColumn = wrapper.find('.js-feature-flag-environments');

      expect(trimText(envColumn.find(GlBadge).text())).toBe('scope');
    });
  });

  describe('with a new version flag', () => {
    let badges;

    beforeEach(() => {
      const newVersionProps = {
        ...props,
        featureFlags: [
          {
            id: 1,
            iid: 1,
            active: true,
            name: 'flag name',
            description: 'flag description',
            destroy_path: 'destroy/path',
            edit_path: 'edit/path',
            version: NEW_VERSION_FLAG,
            scopes: [],
            strategies: [
              {
                name: ROLLOUT_STRATEGY_ALL_USERS,
                parameters: {},
                scopes: [{ environment_scope: '*' }],
              },
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50' },
                scopes: [{ environment_scope: 'production' }, { environment_scope: 'staging' }],
              },
              {
                name: ROLLOUT_STRATEGY_USER_ID,
                parameters: { userIds: '1,2,3,4' },
                scopes: [{ environment_scope: 'review/*' }],
              },
              {
                name: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
                parameters: {},
                user_list: { name: 'test list' },
                scopes: [{ environment_scope: '*' }],
              },
            ],
          },
        ],
      };
      createWrapper(newVersionProps, {
        provide: { csrfToken: 'fakeToken', glFeatures: { featureFlagsNewVersion: true } },
      });

      badges = wrapper.findAll('[data-testid="strategy-badge"]');
    });

    it('shows All Environments if the environment scope is *', () => {
      expect(badges.at(0).text()).toContain('All Environments');
    });

    it('shows the environment scope if another is set', () => {
      expect(badges.at(1).text()).toContain('production');
      expect(badges.at(1).text()).toContain('staging');
      expect(badges.at(2).text()).toContain('review/*');
    });

    it('shows All Users for the default strategy', () => {
      expect(badges.at(0).text()).toContain('All Users');
    });

    it('shows the percent for a percent rollout', () => {
      expect(badges.at(1).text()).toContain('Percent of users - 50%');
    });

    it('shows the number of users for users with ID', () => {
      expect(badges.at(2).text()).toContain('User IDs - 4 users');
    });

    it('shows the name of a user list for user list', () => {
      expect(badges.at(3).text()).toContain('User List - test list');
    });
  });

  it('renders a feature flag without an iid', () => {
    delete props.featureFlags[0].iid;
    createWrapper(props);

    expect(wrapper.find('.js-feature-flag-id').exists()).toBe(true);
    expect(trimText(wrapper.find('.js-feature-flag-id').text())).toBe('');
  });
});
