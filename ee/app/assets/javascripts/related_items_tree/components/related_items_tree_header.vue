<script>
import { mapState, mapActions } from 'vuex';

import { GlTooltip, GlIcon } from '@gitlab/ui';

import { issuableTypesMap } from 'ee/related_issues/constants';

import EpicActionsSplitButton from './epic_issue_actions_split_button.vue';
import EpicHealthStatus from './epic_health_status.vue';

export default {
  components: {
    GlTooltip,
    GlIcon,
    EpicHealthStatus,
    EpicActionsSplitButton,
  },
  computed: {
    ...mapState([
      'parentItem',
      'descendantCounts',
      'healthStatus',
      'allowSubEpics',
      'allowIssuableHealthStatus',
    ]),
    totalEpicsCount() {
      return this.descendantCounts.openedEpics + this.descendantCounts.closedEpics;
    },
    totalIssuesCount() {
      return this.descendantCounts.openedIssues + this.descendantCounts.closedIssues;
    },
    showHealthStatus() {
      return this.healthStatus && this.allowIssuableHealthStatus;
    },
  },
  methods: {
    ...mapActions([
      'toggleCreateIssueForm',
      'toggleAddItemForm',
      'toggleCreateEpicForm',
      'setItemInputValue',
    ]),
    showAddIssueForm() {
      this.setItemInputValue('');
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.ISSUE,
        toggleState: true,
      });
    },
    showCreateIssueForm() {
      this.toggleCreateIssueForm({ toggleState: true });
    },
    showAddEpicForm() {
      this.toggleAddItemForm({
        issuableType: issuableTypesMap.EPIC,
        toggleState: true,
      });
    },
    showCreateEpicForm() {
      this.toggleCreateEpicForm({ toggleState: true });
    },
  },
};
</script>

<template>
  <div class="card-header d-flex px-2 flex-column flex-sm-row">
    <div class="d-inline-flex flex-grow-1 lh-100 align-middle mb-2 mb-sm-0">
      <gl-tooltip :target="() => $refs.countBadge">
        <p v-if="allowSubEpics" class="font-weight-bold m-0">
          {{ __('Epics') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openedEpics} open, %{closedEpics} closed'), {
                openedEpics: descendantCounts.openedEpics,
                closedEpics: descendantCounts.closedEpics,
              })
            }}
          </span>
        </p>
        <p class="font-weight-bold m-0">
          {{ __('Issues') }} &#8226;
          <span class="text-secondary-400 font-weight-normal"
            >{{
              sprintf(__('%{openedIssues} open, %{closedIssues} closed'), {
                openedIssues: descendantCounts.openedIssues,
                closedIssues: descendantCounts.closedIssues,
              })
            }}
          </span>
        </p>
      </gl-tooltip>
      <div ref="countBadge" class="issue-count-badge text-secondary p-0 pr-3">
        <span v-if="allowSubEpics" class="d-inline-flex align-items-center">
          <gl-icon name="epic" class="mr-1" />
          {{ totalEpicsCount }}
        </span>
        <span class="d-inline-flex align-items-center" :class="{ 'ml-3': allowSubEpics }">
          <gl-icon name="issues" class="mr-1" />
          {{ totalIssuesCount }}
        </span>
      </div>
      <epic-health-status v-if="showHealthStatus" :health-status="healthStatus" />
    </div>
    <div
      v-if="parentItem.userPermissions.adminEpic"
      class="d-inline-flex flex-column flex-sm-row js-button-container"
    >
      <epic-actions-split-button
        :allow-sub-epics="allowSubEpics"
        class="js-add-epics-issues-button qa-add-epics-button mb-2 mb-sm-0"
        @showAddIssueForm="showAddIssueForm"
        @showCreateIssueForm="showCreateIssueForm"
        @showAddEpicForm="showAddEpicForm"
        @showCreateEpicForm="showCreateEpicForm"
      />
    </div>
  </div>
</template>
