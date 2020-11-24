import { GlDropdown } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import createMockApollo from 'jest/helpers/mock_apollo_helper';
import VueApollo from 'vue-apollo';
import StateActions from '~/terraform/components/states_table_actions.vue';
import deleteStateMutation from '~/terraform/graphql/mutations/delete_state.mutation.graphql';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('StatesTableActions', () => {
  let wrapper;

  const state = {
    id: 'gid/1',
    name: 'state-1',
  };

  const findRemoveStateBtn = () => wrapper.find('[data-testid="terraform-state-remove-action"]');

  beforeEach(() => {
    wrapper = shallowMount(StateActions, {
      localVue,
      apolloProvider: createMockApollo([]),
      propsData: { state },
      stubs: { GlDropdown },
    });

    return wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a remove button', () => {
    const removeBtn = findRemoveStateBtn();

    expect(removeBtn.exists()).toBe(true);
    expect(removeBtn.text()).toBe('Remove state file and versions');
  });

  describe('when the remove button is clicked', () => {
    describe('when there are no errors', () => {
      beforeEach(() => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { terraformStateDelete: { errors: [] } } });

        findRemoveStateBtn().vm.$emit('click');

        return wrapper.vm.$nextTick();
      });

      it('calls `$apollo.mutate` with `deleteState`', () => {
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith(
          expect.objectContaining({
            mutation: deleteStateMutation,
            variables: {
              stateID: state.id,
            },
          }),
        );
      });

      it('does not display error message', () => {
        expect(wrapper.text()).not.toContain('An error occurred while trying to delete');
      });
    });

    describe('when an error occurs', () => {
      beforeEach(() => {
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { terraformStateDelete: { errors: ['error!'] } } });

        findRemoveStateBtn().vm.$emit('click');

        return wrapper.vm.$nextTick();
      });

      it('displays an error message', () => {
        expect(wrapper.text()).toContain('An error occurred while trying to delete');
      });
    });
  });
});
