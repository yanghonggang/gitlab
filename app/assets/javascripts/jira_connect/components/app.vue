<script>
import { GlAlert } from '@gitlab/ui';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
  },
  computed: {
    state() {
      return this.$root.$data.state || {};
    },
    error() {
      return this.state.error;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="error">
      {{ error }}
    </gl-alert>
  </div>
</template>
