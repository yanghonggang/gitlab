import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { random } from 'lodash';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const resolvers = {
  Query: {
    dastSiteValidations: (_, { normalizedTargetUrls }) => {
      return {
        nodes: normalizedTargetUrls.map(url => {
          const randNumber = random(100);
          let validationStatus = 'INPROGRESS_VALIDATION';
          if (randNumber < 20) {
            validationStatus = 'PASSED_VALIDATION';
          } else if (randNumber > 80) {
            validationStatus = 'FAILED_VALIDATION';
          }
          return {
            normalizedTargetUrl: url,
            status: validationStatus,
            __typename: 'DastSiteValidation',
          };
        }),
        __typename: 'DastSiteValidations',
      };
    },
  },
};

export default new VueApollo({
  defaultClient: createDefaultClient(resolvers, {
    assumeImmutableResults: true,
  }),
});
