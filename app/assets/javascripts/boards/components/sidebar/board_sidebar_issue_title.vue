<script>
import { mapGetters, mapActions } from 'vuex';
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import createFlash from '~/flash';
import { __ } from '~/locale';

export default {
  components: {
    GlForm,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    BoardEditableItem,
  },
  directives: {
    autofocusonshow,
  },
  data() {
    return {
      title: '',
      loading: false,
      showChangesAlert: false,
    };
  },
  computed: {
    ...mapGetters({ issue: 'activeIssue' }),

    projectPath() {
      const referencePath = this.issue.referencePath || '';
      return referencePath.slice(0, referencePath.indexOf('#'));
    },
    validationState() {
      return Boolean(this.title);
    },
  },
  watch: {
    issue: {
      handler(updatedIssue) {
        this.title = updatedIssue.title;
      },
      immediate: true,
    },
  },
  methods: {
    ...mapActions(['setActiveIssueTitle']),
    cancel() {
      this.title = this.issue.title;
      this.$refs.sidebarItem.collapse();
    },
    async setTitle() {
      this.$refs.sidebarItem.collapse();

      if (this.title === this.issue.title) {
        return;
      }

      try {
        this.loading = true;
        await this.setActiveIssueTitle({ title: this.title, projectPath: this.projectPath });
      } catch (e) {
        this.title = this.issue.title;
        createFlash({ message: this.$options.i18n.updateTitleError });
      } finally {
        this.loading = false;
      }
    },
    handleOffClick() {
      if (this.title !== this.issue.title) {
        this.showChangesAlert = true;
        this.$refs.input.$el.focus();

        return;
      }

      this.$refs.sidebarItem.collapse();
    },
  },
  i18n: {
    issueTitlePlaceholder: __('Issue title'),
    submitButton: __('Save changes'),
    cancelButton: __('Cancel'),
    updateTitleError: __('An error occurred when updating the issue title'),
    invalidFeedback: __('An issue title is required'),
    reviewYourChanges: __('Please review your changes to the issue title in order to proceed'),
  },
};
</script>

<template>
  <board-editable-item
    ref="sidebarItem"
    :loading="loading"
    toggle-header
    :handle-off-click="false"
    @off-click="handleOffClick"
    @close="showChangesAlert = false"
  >
    <template #title>
      <span class="gl-font-weight-bold" data-testid="issue-title">{{ issue.title }}</span>
    </template>
    <template #collapsed>
      <span class="gl-text-gray-800">{{ issue.referencePath }}</span>
    </template>
    <template>
      <gl-alert v-if="showChangesAlert" variant="danger" class="gl-mb-5" :dismissible="false">
        {{ $options.i18n.reviewYourChanges }}
      </gl-alert>
      <gl-form @submit.prevent="setTitle">
        <gl-form-group :invalid-feedback="$options.i18n.invalidFeedback" :state="validationState">
          <gl-form-input
            ref="input"
            v-model="title"
            v-autofocusonshow
            :placeholder="$options.i18n.issueTitlePlaceholder"
            :state="validationState"
          />
        </gl-form-group>

        <div class="gl-display-flex gl-w-full gl-justify-content-space-between gl-mt-5">
          <gl-button variant="success" size="small" data-testid="submit-button" @click="setTitle">
            {{ $options.i18n.submitButton }}
          </gl-button>

          <gl-button size="small" data-testid="cancel-button" @click="cancel">
            {{ $options.i18n.cancelButton }}
          </gl-button>
        </div>
      </gl-form>
    </template>
  </board-editable-item>
</template>
