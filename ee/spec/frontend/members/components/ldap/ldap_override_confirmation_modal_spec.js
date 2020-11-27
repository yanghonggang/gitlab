import { GlModal } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { member } from 'jest/members/mock_data';
import { LDAP_OVERRIDE_CONFIRMATION_MODAL_ID } from 'ee/members/constants';
import LdapOverrideConfirmationModal from 'ee/members/components/ldap/ldap_override_confirmation_modal.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('LdapOverrideConfirmationModal', () => {
  let wrapper;
  let resolveUpdateLdapOverride;
  let actions;
  const $toast = {
    show: jest.fn(),
  };

  const createStore = (state = {}) => {
    actions = {
      updateLdapOverride: jest.fn(
        () =>
          new Promise(resolve => {
            resolveUpdateLdapOverride = resolve;
          }),
      ),
      hideLdapOverrideConfirmationModal: jest.fn(),
    };

    return new Vuex.Store({
      state: {
        memberToOverride: member,
        ldapOverrideConfirmationModalVisible: true,
        ...state,
      },
      actions,
    });
  };

  const createComponent = state => {
    wrapper = mount(LdapOverrideConfirmationModal, {
      localVue,
      store: createStore(state),
      attrs: {
        static: true,
      },
      mocks: {
        $toast,
      },
    });
  };

  const findModal = () => wrapper.find(GlModal);
  const getByText = (text, options) =>
    createWrapper(within(findModal().element).getByText(text, options));
  const getEditPermissionsButton = () =>
    getByText('Edit permissions', { selector: 'button > span' });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when modal is open', () => {
    beforeEach(async () => {
      createComponent();
      await nextTick();
    });

    it('sets modal ID', () => {
      expect(findModal().props('modalId')).toBe(LDAP_OVERRIDE_CONFIRMATION_MODAL_ID);
    });

    it('displays modal title', () => {
      expect(getByText('Edit permissions', { selector: 'h4' }).exists()).toBe(true);
    });

    it('displays modal body', () => {
      expect(
        getByText(
          `${member.user.name} is currently an LDAP user. Editing their permissions will override the settings from the LDAP group sync.`,
        ).exists(),
      ).toBe(true);
    });

    it('calls `hideLdapOverrideConfirmationModal` action when modal is closed', () => {
      getByText('Cancel').trigger('click');

      expect(actions.hideLdapOverrideConfirmationModal).toHaveBeenCalled();
    });

    describe('When "Edit permissions" button is clicked', () => {
      beforeEach(async () => {
        getEditPermissionsButton().trigger('click');
      });

      it('calls `updateLdapOverride` Vuex action', () => {
        expect(actions.updateLdapOverride).toHaveBeenCalledWith(expect.any(Object), {
          memberId: member.id,
          override: true,
        });
      });

      it('displays toast when successful', async () => {
        resolveUpdateLdapOverride();
        await waitForPromises();

        expect($toast.show).toHaveBeenCalledWith('LDAP override enabled.');
      });

      it('sets primary button to loading state while waiting for `updateLdapOverride` to resolve', async () => {
        expect(getEditPermissionsButton().element.closest('button[disabled="disabled"]')).not.toBe(
          null,
        );

        resolveUpdateLdapOverride();
        await waitForPromises();

        expect(getEditPermissionsButton().element.closest('button[disabled="disabled"]')).toBe(
          null,
        );
      });
    });
  });

  it('modal does not show when `ldapOverrideConfirmationModalVisible` is `false`', () => {
    createComponent({ ldapOverrideConfirmationModalVisible: false });

    expect(findModal().vm.$attrs.visible).toBe(false);
  });
});
