import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { member } from 'jest/members/mock_data';
import LdapOverrideButton from 'ee/members/components/ldap/ldap_override_button.vue';
import UserActionButtons from '~/members/components/action_buttons/user_action_buttons.vue';

describe('UserActionButtons', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(UserActionButtons, {
      propsData: {
        member,
        isCurrentUser: false,
        ...propsData,
      },
    });

    return waitForPromises();
  };

  const findLdapOverrideButton = () => wrapper.find(LdapOverrideButton);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when member has `canOverride` permissions', () => {
    describe('when member is not overridden', () => {
      it('renders LDAP override button', async () => {
        await createComponent({
          permissions: { canOverride: true },
          member: {
            ...member,
            isOverridden: false,
          },
        });

        expect(findLdapOverrideButton().exists()).toBe(true);
      });
    });

    describe('when member is overridden', () => {
      it('does not render the LDAP override button', async () => {
        await createComponent({
          permissions: { canOverride: true },
          member: {
            ...member,
            isOverridden: true,
          },
        });

        expect(findLdapOverrideButton().exists()).toBe(false);
      });
    });
  });

  describe('when member does not have `canOverride` permissions', () => {
    it('does not render the LDAP override button', async () => {
      await createComponent({
        permissions: { canOverride: false },
      });

      expect(findLdapOverrideButton().exists()).toBe(false);
    });
  });
});
