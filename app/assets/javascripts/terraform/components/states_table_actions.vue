<script>
import { GlDropdown, GlDropdownDivider, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import Api from '~/api';
import downloader from '~/lib/utils/downloader';
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
    projectId: {
      required: true,
      type: Number,
    },
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
    downloadVersion() {
      Api.downloadProjectTerraformStateVersion(
        this.projectId,
        this.state.name,
        this.state.latestVersion.version,
      )
        .then(response => {
          downloader({
            fileName: `${this.state.name}.json`,
            url: window.URL.createObjectURL(response.data),
          });
        })
        .catch(() => {});
    },
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

    <gl-dropdown-item v-if="state.latestVersion" icon-name="download" @click="downloadVersion">
      {{ s__('Terraform|Download latest (JSON)') }}
    </gl-dropdown-item>

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
