<script>
import {
  GlAlert,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import deleteState from '../graphql/mutations/delete_state.mutation.graphql';

export default {
  i18n: {
    actions: s__('Terraform|Actions'),
    delete: s__('Terraform|Remove state file and versions'),
    deleteError: s__('Terraform|An error occurred while trying to delete'),
  },
  components: {
    GlAlert,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
  },
  props: {
    state: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      loading: false,
      error: null,
    };
  },
  methods: {
    deleteState() {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: deleteState,
          variables: {
            stateID: this.state.id,
          },
          refetchQueries: () => ['getStates'],
          awaitRefetchQueries: true,
          notifyOnNetworkStatusChange: true,
        })
        .then(({ data: { terraformStateDelete: { errors } } }) => {
          if (errors.length) {
            this.error = this.$options.i18n.deleteError;
          }
        })
        .catch(() => {
          this.error = this.$options.i18n.deleteError;
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-justify-content-end gl-flex-direction-column gl-align-items-flex-end gl-pl-3"
  >
    <gl-alert v-if="error" variant="warning" @dismiss="error = null">
      {{ error }}
    </gl-alert>

    <gl-dropdown icon="ellipsis_v" right :loading="loading">
      <gl-dropdown-section-header>
        {{ $options.i18n.actions }}
      </gl-dropdown-section-header>

      <gl-dropdown-divider />

      <gl-dropdown-item icon-name="remove-all" @click="deleteState">
        {{ $options.i18n.delete }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
