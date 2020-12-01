<script>
export default {
  props: {
    users: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentPage: {
      type: Number,
      required: true,
    },
    totalPages: {
      type: Number,
      required: true,
    },
    paths: {
      type: Object,
      required: true,
    }
  },
};
</script>

<template>
  <div>
    Admin Users App
  </div>
</template>
