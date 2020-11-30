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
      currentPipeline: null,
      loadingPipelineId: null,
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
    getPipelineData(pipeline) {
      this.$apollo.addSmartQuery('currentPipeline', {
        query: getPipelineDetails,
        variables() {
          return {
            projectPath: pipeline.project.fullPath,
            iid: pipeline.id,
          };
        },
        update(data) {
          return unwrapPipelineData(pipeline.id, data);
        },
        error(err){
          console.error('graphQL error:', err);
        },
        watchLoading(isLoading) {
          if (isLoading) {
            this.loadingPipelineId = pipeline.id;
          } else {
            this.loadingPipelineId = null;
          }
        }
      })
    },
    isExpanded(id){
      return Boolean(this.currentPipeline?.id && id === this.currentPipeline.id);
    },
    isLoadingPipeline(id) {
      return this.$apollo.queries.currentPipeline?.loading && this.loadingPipelineId === id;
    },
    onPipelineClick(pipeline) {
      /* If the clicked pipeline has been expanded already, close it, clear, exit */
      if (this.currentPipeline?.id === pipeline.id) {
        this.pipelineExpanded = false;
        this.currentPipeline = null;
        return;
      }

      /* Set the loading id */
      this.loadingPipelineId = pipeline.id;

      /*
        Expand the pipeline.
        If this was not a toggle close action, and
        it was already showing a different pipeline, then
        this will be a no-op, but that doesn't matter.
      */
      this.pipelineExpanded = true;

      this.getPipelineData(pipeline);

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
            :is-loading="isLoadingPipeline(pipeline.id)"
            :pipeline="pipeline"
            :column-title="columnTitle"
            :type="type"
            :expanded="(isExpanded(pipeline.id))"
            @downstreamHovered="onDownstreamHovered"
            @pipelineClicked="onPipelineClick(pipeline)"
            @pipelineExpandToggle="onPipelineExpandToggle"
          />
          <div v-if="(isExpanded(pipeline.id))" class="gl-display-inline-block">
            <pipeline-graph
              v-if="currentPipeline"
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
