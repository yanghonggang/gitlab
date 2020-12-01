<script>
import { mapActions, mapState } from 'vuex';
import { GlToggle, GlFormGroup, GlFormTextarea, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapComputed } from '~/vuex_shared/bindings';

export default {
  name: 'MaintenanceModeSettingsApp',
  components: {
    GlToggle,
    GlFormGroup,
    GlFormTextarea,
    GlButton,
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['isLoading']),
    ...mapComputed([
      { key: 'maintenanceEnabled', updateFn: 'setMaintenanceEnabled' },
      { key: 'bannerMessage', updateFn: 'setBannerMessage' },
    ]),
  },
  created() {
    this.fetchMaintenanceModeSettings();
  },
  methods: {
    ...mapActions(['fetchMaintenanceModeSettings', 'updateMaintenanceModeSettings']),
  },
};
</script>
<template>
  <section>
    <gl-loading-icon v-if="isLoading" size="xl" />
    <form v-else @submit.prevent="updateMaintenanceModeSettings">
      <div class="gl-display-flex gl-align-items-center gl-mb-4">
        <gl-toggle v-model="maintenanceEnabled" />
        <div class="gl-ml-3">
          <p class="gl-mb-0">{{ __('Enable maintenance mode') }}</p>
          <p class="gl-mb-0 gl-text-gray-500">
            {{
              __(
                'Non-admin users can sign in with read-only access and make read-only API requests.',
              )
            }}
          </p>
        </div>
      </div>
      <gl-form-group label="Banner Message" label-for="maintenanceBannerMessage">
        <gl-form-textarea
          id="maintenanceBannerMessage"
          v-model="bannerMessage"
          :placeholder="
            __(`GitLab is undergoing maintenance and is operating in a read-only mode.`)
          "
        />
      </gl-form-group>
      <gl-button variant="success" type="submit">{{ __('Save changes') }}</gl-button>
    </form>
  </section>
</template>
