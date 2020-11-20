<script>
import { __, sprintf } from '~/locale';
import { toNounSeriesText } from '~/lib/utils/grammar';

export default {
  props: {
    emails: {
      type: Array,
      required: true,
    },
  },
  computed: {
    title() {
      return sprintf(__('%{emails} will be notified of your comment.'), {
        emails: toNounSeriesText(this.emails),
      });
    },
  },
};
</script>

<template>
  <div class="issuable-note-warning">
    {{ title }}
  </div>
</template>
