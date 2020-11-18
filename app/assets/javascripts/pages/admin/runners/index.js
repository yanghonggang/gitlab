import initFilteredSearch from '~/pages/search/init_filtered_search';
import AdminRunnersFilteredSearchTokenKeys from '~/filtered_search/admin_runners_filtered_search_token_keys';
import { FILTERED_SEARCH } from '~/pages/constants';

document.addEventListener('DOMContentLoaded', () => {
  initFilteredSearch({
    page: FILTERED_SEARCH.ADMIN_RUNNERS,
    filteredSearchTokenKeys: AdminRunnersFilteredSearchTokenKeys,
    useDefaultState: true,
  });
});
