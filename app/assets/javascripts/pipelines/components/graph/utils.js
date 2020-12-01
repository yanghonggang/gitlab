import { getIdFromGraphQLId } from '~/graphql_shared/utils';


const unwrapPipelineData = (mainPipelineProjectPath, data) => {
  if (!data?.project?.pipeline) {
    return null;
  }

  const { pipeline } = data.project;

  const {
    upstream,
    downstream: { nodes: downstream },
    stages: { nodes: stages },
  } = pipeline;

  const unwrappedNestedGroups = stages.map(stage => {
    const {
      groups: { nodes: groups },
    } = stage;
    return { ...stage, groups };
  });

  const nodes = unwrappedNestedGroups.map(({ name, status, groups }) => {
    const groupsWithJobs = groups.map(group => {
      const jobs = group.jobs.nodes.map(job => {
        const { needs } = job;
        return { ...job, needs: needs.nodes.map(need => need.name) };
      });

      return { ...group, jobs };
    });

    return { name, status, groups: groupsWithJobs };
  });

  const addMulti = linkedPipeline => {
    return { ...linkedPipeline, multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath };
  };

  const transformId = linkedPipeline => {
    return { ...linkedPipeline, id: getIdFromGraphQLId(linkedPipeline.id)}
  };

  return {
    ...pipeline,
    id: getIdFromGraphQLId(pipeline.id),
    stages: nodes,
    upstream: upstream ? [upstream].map(addMulti).map(transformId) : [],
    downstream: downstream ? downstream.map(addMulti).map(transformId) : [],
  };
};

export { unwrapPipelineData };
