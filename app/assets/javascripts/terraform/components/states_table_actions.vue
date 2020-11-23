<script>
import { GlDropdown, GlDropdownDivider, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import deleteState from '../graphql/mutations/delete_state.mutation.graphql';
import lockState from '../graphql/mutations/lock_state.mutation.graphql';
import unlockState from '../graphql/mutations/unlock_state.mutation.graphql';

export default {
  components: {
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
    };
  },
  methods: {
    deleteState() {
      this.stateMutation(deleteState);
    },
    lockState() {
      this.stateMutation(lockState);
    },
    unlockState() {
      this.stateMutation(unlockState);
    },
    stateMutation(mutation) {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation,
          variables: {
            stateID: this.state.id,
          },
          refetchQueries: () => ['getStates'],
          awaitRefetchQueries: true,
        })
        .then(() => {
          this.loading = false;
        })
        .catch(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <gl-dropdown icon="ellipsis_v" right :disabled="loading">
    <gl-dropdown-section-header>
      {{ s__('Terraform|Actions') }}
    </gl-dropdown-section-header>

    <gl-dropdown-item v-if="state.lockedAt" icon-name="lock-open" @click="unlockState">
      {{ s__('Terraform|UnLock') }}
    </gl-dropdown-item>

    <gl-dropdown-item v-else icon-name="lock" @click="lockState">
      {{ s__('Terraform|Lock') }}
    </gl-dropdown-item>

    <gl-dropdown-divider />

    <gl-dropdown-item icon-name="remove-all" @click="deleteState">
      {{ s__('Terraform|Remove state file and versions') }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
