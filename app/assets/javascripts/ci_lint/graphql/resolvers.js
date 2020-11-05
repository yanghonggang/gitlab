import axios from '~/lib/utils/axios_utils';

const resolvers = {
  Mutation: {
    lintCI: (_, { endpoint, content, dry_run }) => {
      return axios.post(endpoint, { content, dry_run }).then(({ data }) => ({
        valid: data.valid,
        errors: data.errors,
        warnings: data.warnings,
        jobs: data.jobs.map(job => {
          const only = job.only ? { refs: job.only.refs, __typename: 'CiLintJobOnlyPolicy' } : null;

          return {
            name: job.name,
            stage: job.stage,
            beforeScript: job.before_script,
            script: job.script,
            afterScript: job.after_script,
            tagList: job.tag_list,
            environment: job.environment,
            when: job.when,
            allowFailure: job.allow_failure,
            only,
            except: job.except,
            __typename: 'CiLintJob',
          };
        }),
        __typename: 'CiLintContent',
      }));
    },
  },
};

export default resolvers;
