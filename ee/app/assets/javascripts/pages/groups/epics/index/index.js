import FilteredSearchTokenKeysEpics from 'ee/filtered_search/filtered_search_token_keys_epics';
import initEpicCreateApp from 'ee/epic/epic_bundle';
import initEpicsList from 'ee/epics_list/epics_list_bundle';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';

const EPIC_BULK_UPDATE_PREFIX = 'epic_';

if (gon.features.vueEpicsList) {
  initEpicsList({
    mountPointSelector: '#js-epis-list',
  });
} else {
  initFilteredSearch({
    page: 'epics',
    isGroup: true,
    isGroupDecendent: true,
    useDefaultState: true,
    filteredSearchTokenKeys: FilteredSearchTokenKeysEpics,
    stateFiltersSelector: '.epics-state-filters',
  });

  initEpicCreateApp(true);

  issuableInitBulkUpdateSidebar.init(EPIC_BULK_UPDATE_PREFIX);
}
