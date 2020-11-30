<script>
import { GlLoadingIcon } from '@gitlab/ui';
import getPipelineDetails from '../../graphql/queries/get_pipeline_details.query.graphql';
import LinkedPipeline from './linked_pipeline.vue';
import { UPSTREAM, DOWNSTREAM } from './constants';
import { unwrapPipelineData } from './utils';

export default {
  components: {
    GlLoadingIcon,
    LinkedPipeline,
    PipelineGraph: () => import('./graph_component.vue'),
  },
  props: {
    columnTitle: {
      type: String,
      required: true,
    },
    linkedPipelines: {
      type: Array,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentPipelineId: null,
      currentPipeline: null,
      pipelineExpanded: false,
    }
  },
  computed: {
    columnClass() {
      const positionValues = {
        right: 'gl-ml-11',
        left: 'gl-mr-7',
      };
      return `graph-position-${this.graphPosition} ${positionValues[this.graphPosition]}`;
    },
    graphPosition() {
      return this.isUpstream ? 'left' : 'right';
    },
    isUpstream() {
      return this.type === UPSTREAM;
    },
  },
  methods: {
    isExpanded(id){
      return Boolean(this.currentPipeline?.id && id === this.currentPipeline.id);
    },
    onPipelineClick(downstreamNode, pipeline, index) {
      this.$emit('linkedPipelineClick', pipeline, index, downstreamNode);
    },
    onDownstreamHovered(jobName) {
      this.$emit('downstreamHovered', jobName);
    },
    onPipelineExpandToggle(jobName, expanded) {
      // Highlighting only applies to downstream pipelines
      if (this.isUpstream) {
        return;
      }

      this.$emit('pipelineExpandToggle', jobName, expanded);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <div :class="columnClass" class="linked-pipelines-column">
      <div class="stage-name linked-pipelines-column-title">{{ columnTitle }}</div>
      <ul class="gl-pl-0">
        <li v-for="(pipeline, index) in linkedPipelines" class="gl-display-flex" :class="{'gl-flex-direction-row-reverse': isUpstream}">
          <linked-pipeline
            :key="pipeline.id"
            class="gl-display-inline-block"
            :pipeline="pipeline"
            :column-title="columnTitle"
            :type="type"
            :expanded="(isExpanded(pipeline.id))"
            @downstreamHovered="onDownstreamHovered"
            @pipelineClicked="onPipelineClick(pipeline, index)"
            @pipelineExpandToggle="onPipelineExpandToggle"
          />
          <div v-if="(isExpanded(pipeline.id))" class="gl-display-inline-block" :style="{ width: 'max-content', background: 'mistyrose'}">
            <gl-loading-icon v-if="$apollo.queries.currentPipeline.loading" class="m-auto" size="lg" />
            <pipeline-graph
              v-else
              :type="type"
              class="d-inline-block"
              :pipeline="currentPipeline"
              :is-linked-pipeline="true"
            />
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
