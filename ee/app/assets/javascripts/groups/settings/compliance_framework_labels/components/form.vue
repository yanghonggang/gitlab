<script>
import getComplianceFrameworkQuery from '../graphql/queries/get_compliance_framework.query.graphql';

export default {
  components: {
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      complianceFramework: [],
    };
  },
  apollo: {
    complianceFramework: {
      query: getComplianceFrameworkQuery,
      update(data) {
        console.log(data);
        return data;
      },
      error(error) {
        console.error(error);
      }
    }
  },
};
</script>
<template>
  <p>FORM</p>
</template>
