import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';

import { FilterState } from '../constants';

export default {
  computed: {
    reference() {
      return `REQ-${this.requirement?.iid}`;
    },
    titleHtml() {
      return this.requirement?.titleHtml;
    },
    descriptionHtml() {
      return this.requirement?.descriptionHtml;
    },
    isArchived() {
      return this.requirement?.state === FilterState.archived;
    },
    author() {
      return this.requirement?.author;
    },
    createdAtFormatted() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: getTimeago().format(this.requirement?.createdAt),
      });
    },
    updatedAtFormatted() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: getTimeago().format(this.requirement?.updatedAt),
      });
    },
    testReport() {
      return this.requirement?.testReports.nodes[0];
    },
    canUpdate() {
      return this.requirement?.userPermissions.updateRequirement;
    },
    canArchive() {
      return this.requirement?.userPermissions.adminRequirement;
    },
  },
};
