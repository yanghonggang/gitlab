<script>
import { mapState, mapActions } from 'vuex';
import { isEmpty } from 'lodash';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import SearchableDropdown from './searchable_dropdown.vue';
import { ANY_OPTION, PROJECT_DATA } from '../constants';

export default {
  name: 'ProjectFilter',
  components: {
    SearchableDropdown,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState(['projects', 'fetchingProjects']),
    selectedProject() {
      return isEmpty(this.initialData) ? ANY_OPTION : this.initialData;
    },
  },
  methods: {
    ...mapActions(['fetchProjects']),
    handleProjectChange(project) {
      visitUrl(setUrlParams({ [PROJECT_DATA.queryParam]: project.id }));
    },
  },
  PROJECT_DATA,
};
</script>

<template>
  <searchable-dropdown
    :header-text="$options.PROJECT_DATA.headerText"
    :selected-display-value="$options.PROJECT_DATA.selectedDisplayValue"
    :items-display-value="$options.PROJECT_DATA.itemsDisplayValue"
    :loading="fetchingProjects"
    :selected-item="selectedProject"
    :items="projects"
    @search="fetchProjects"
    @change="handleProjectChange"
  />
</template>
