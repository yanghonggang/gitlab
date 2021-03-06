<script>
import { GlBadge, GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'PackageTags',
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tagDisplayLimit: {
      type: Number,
      required: false,
      default: 2,
    },
    tags: {
      type: Array,
      required: true,
      default: () => [],
    },
    hideLabel: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tagCount() {
      return this.tags.length;
    },
    tagsToRender() {
      return this.tags.slice(0, this.tagDisplayLimit);
    },
    moreTagsDisplay() {
      return Math.max(0, this.tags.length - this.tagDisplayLimit);
    },
    moreTagsTooltip() {
      if (this.moreTagsDisplay) {
        return this.tags
          .slice(this.tagDisplayLimit)
          .map(x => x.name)
          .join(', ');
      }

      return '';
    },
    tagsDisplay() {
      return n__('%d tag', '%d tags', this.tagCount);
    },
  },
  methods: {
    tagBadgeClass(index) {
      return {
        'd-none': true,
        'd-block': this.tagCount === 1,
        'd-md-block': this.tagCount > 1,
        'append-right-4': index !== this.tagsToRender.length - 1,
        'prepend-left-8': !this.hideLabel && index === 0,
      };
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <div v-if="!hideLabel" ref="tagLabel" class="d-flex align-items-center">
      <gl-icon name="labels" class="append-right-8" />
      <strong class="js-tags-count">{{ tagsDisplay }}</strong>
    </div>

    <gl-badge
      v-for="(tag, index) in tagsToRender"
      :key="index"
      ref="tagBadge"
      :class="tagBadgeClass(index)"
      variant="info"
      >{{ tag.name }}</gl-badge
    >

    <gl-badge
      v-if="moreTagsDisplay"
      ref="moreBadge"
      v-gl-tooltip
      variant="light"
      :title="moreTagsTooltip"
      class="d-none d-md-block prepend-left-4"
      ><gl-sprintf :message="__('+%{tags} more')">
        <template #tags>
          {{ moreTagsDisplay }}
        </template>
      </gl-sprintf></gl-badge
    >

    <gl-badge
      v-if="moreTagsDisplay && hideLabel"
      ref="moreBadge"
      variant="light"
      class="d-md-none prepend-left-4"
      >{{ tagsDisplay }}</gl-badge
    >
  </div>
</template>
