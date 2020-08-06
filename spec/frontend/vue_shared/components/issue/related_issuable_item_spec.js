import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'jest/helpers/test_constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import { defaultAssignees, defaultMilestone } from './related_issuable_mock_data';

describe('RelatedIssuableItem', () => {
  let wrapper;

  function mountComponent({ mountMethod = mount, stubs = {}, props = {}, slots = {} } = {}) {
    wrapper = mountMethod(RelatedIssuableItem, {
      propsData: props,
      slots,
      stubs,
    });
  }

  const props = {
    idKey: 1,
    displayReference: 'gitlab-org/gitlab-test#1',
    pathIdSeparator: '#',
    path: `${TEST_HOST}/path`,
    title: 'title',
    confidential: true,
    dueDate: '1990-12-31',
    weight: 10,
    createdAt: '2018-12-01T00:00:00.00Z',
    milestone: defaultMilestone,
    assignees: defaultAssignees,
    eventNamespace: 'relatedIssue',
  };
  const slots = {
    dueDate: '<div class="js-due-date-slot"></div>',
    weight: '<div class="js-weight-slot"></div>',
  };

  beforeEach(() => {
    mountComponent({ props, slots });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('contains issuable-info-container class when canReorder is false', () => {
    expect(wrapper.props('canReorder')).toBe(false);
    expect(wrapper.find('.issuable-info-container').exists()).toBe(true);
  });

  it('does not render token state', () => {
    expect(wrapper.find('.text-secondary svg').exists()).toBe(false);
  });

  it('does not render remove button', () => {
    expect(wrapper.find({ ref: 'removeButton' }).exists()).toBe(false);
  });

  describe('token title', () => {
    it('links to computedPath', () => {
      expect(wrapper.find('.item-title a').attributes('href')).toEqual(wrapper.props('path'));
    });

    it('renders confidential icon', () => {
      expect(wrapper.find('.confidential-icon').exists()).toBe(true);
    });

    it('renders title', () => {
      expect(wrapper.find('.item-title a').text()).toEqual(props.title);
    });
  });

  describe('token state', () => {
    const tokenState = () => wrapper.find({ ref: 'iconElementXL' });

    beforeEach(() => {
      wrapper.setProps({ state: 'opened' });
    });

    it('renders if hasState', () => {
      expect(tokenState().exists()).toBe(true);
    });

    it('renders state title', () => {
      const stateTitle = tokenState().attributes('title');
      const formattedCreateDate = formatDate(props.createdAt);

      expect(stateTitle).toContain('<span class="bold">Opened</span>');
      expect(stateTitle).toContain(`<span class="text-tertiary">${formattedCreateDate}</span>`);
    });

    it('renders aria label', () => {
      expect(tokenState().attributes('aria-label')).toEqual('opened');
    });

    it('renders open icon when open state', () => {
      expect(tokenState().classes('issue-token-state-icon-open')).toBe(true);
    });

    it('renders close icon when close state', async () => {
      wrapper.setProps({
        state: 'closed',
        closedAt: '2018-12-01T00:00:00.00Z',
      });
      await wrapper.vm.$nextTick();

      expect(tokenState().classes('issue-token-state-icon-closed')).toBe(true);
    });
  });

  describe('token metadata', () => {
    const tokenMetadata = () => wrapper.find('.item-meta');

    it('renders item path and ID', () => {
      const pathAndID = tokenMetadata()
        .find('.item-path-id')
        .text();

      expect(pathAndID).toContain('gitlab-org/gitlab-test');
      expect(pathAndID).toContain('#1');
    });

    it('renders milestone icon and name', () => {
      const milestoneIcon = tokenMetadata().find('.item-milestone svg use');
      const milestoneTitle = tokenMetadata().find('.item-milestone .milestone-title');

      expect(milestoneIcon.attributes('href')).toContain('clock');
      expect(milestoneTitle.text()).toContain('Milestone title');
    });

    it('renders due date component with correct due date', () => {
      expect(wrapper.find(IssueDueDate).props('date')).toBe(props.dueDate);
    });
  });

  describe('token assignees', () => {
    it('renders assignees avatars', () => {
      // Expect 2 times 2 because assignees are rendered twice, due to layout issues
      expect(wrapper.findAll('.item-assignees .user-avatar-link').length).toBeDefined();

      expect(wrapper.find('.item-assignees .avatar-counter').text()).toContain('+2');
    });
  });

  describe('action buttons', () => {
    const removeSpy = jest.fn();
    const removeButton = { action: 'remove', icon: 'close', tooltip: 'Remove', onClick: removeSpy };
    const genericButton1 = { icon: 'play', tooltip: 'tooltip b', onClick: () => {} };
    const actionButtons = () => wrapper.findAll('[data-testid="action-button"]');
    const findRemoveButton = () => actionButtons().at(0);
    const buttons = [removeButton, genericButton1];

    it('renders action buttons', async () => {
      wrapper.setProps({ actionButtons: buttons });

      await wrapper.vm.$nextTick();

      expect(actionButtons()).toHaveLength(buttons.length);
    });

    it('triggers onRemoveRequest when clicked', async () => {
      wrapper.setProps({ actionButtons: buttons });

      await wrapper.vm.$nextTick();

      findRemoveButton().trigger('click');

      await wrapper.vm.$nextTick();

      expect(removeSpy).toHaveBeenCalled();
    });

    it('renders disabled button when removeDisabled', async () => {
      const disabledRemoveButton = { ...removeButton, isDisabled: true };
      wrapper.setProps({ actionButtons: [disabledRemoveButton] });

      await wrapper.vm.$nextTick();

      expect(findRemoveButton().attributes('disabled')).toEqual('disabled');
    });
  });
});
