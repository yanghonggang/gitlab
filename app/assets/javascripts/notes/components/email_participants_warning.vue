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
      if (this.moreParticipantsAvailable) {
        return this.lessParticipants.join(', ');
      }
      return sprintf(__('%{emails}'), {
        emails: toNounSeriesText(this.emails),
      });
    },
    lessParticipants() {
      return this.emails.slice(0, this.numberOfLessParticipants);
    },
    moreLabel() {
      return sprintf(__('and %{moreCount} more'), {
        moreCount: this.emails.length - this.numberOfLessParticipants,
      });
    },
    moreParticipantsAvailable() {
      return !this.isShowingMoreParticipants && this.emails.length > this.numberOfLessParticipants;
    },
  },
  methods: {
    showMoreParticipants() {
      this.isShowingMoreParticipants = true;
    },
  },
};
</script>

<template>
  <div class="issuable-note-warning gl-border-t-1 gl-border-t-solid gl-border-t-gray-100">
    {{ title }}
    <button
      v-if="moreParticipantsAvailable"
      type="button"
      class="btn-transparent btn-link"
      @click="showMoreParticipants"
    >
      {{ moreLabel }}
    </button>
    {{ __(' will be notified of your comment.') }}
  </div>
</template>
