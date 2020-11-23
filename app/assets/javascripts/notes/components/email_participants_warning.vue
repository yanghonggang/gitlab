<script>
import { __, sprintf } from '~/locale';
import { toNounSeriesText } from '~/lib/utils/grammar';

export default {
  props: {
    emails: {
      type: Array,
      required: true,
    },
    numberOfLessParticipants: {
      type: Number,
      required: false,
      default: 3,
    },
  },
  data() {
    return {
      isShowingMoreParticipants: false,
    };
  },
  computed: {
    title() {
      return sprintf(__('%{emails} will be notified of your comment.'), {
        emails: toNounSeriesText(this.emails),
      });
    },
    lessParticipants() {
      return this.emails.slice(0, this.numberOfLessParticipants);
    },
    visibleParticipants() {
      return this.isShowingMoreParticipants ? this.emails : this.lessParticipants;
    },
    hasMoreParticipants() {
      return this.participants.length > this.numberOfLessParticipants;
    },
    toggleLabel() {
      let label = '';
      if (this.isShowingMoreParticipants) {
        label = __('- show less');
      } else {
        label = sprintf(__('+ %{moreCount} more'), {
          moreCount: this.participants.length - this.numberOfLessParticipants,
        });
      }

      return label;
    },
  },
};
</script>

<template>
  <div class="issuable-note-warning">
    {{ title }}
  </div>
</template>
