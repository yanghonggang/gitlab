import setHighlightClass from 'ee_else_ce/search/highlight_blob_search_result';
import Project from '~/pages/projects/project';
import refreshCounts from './refresh_counts';
import { initSearchApp } from '~/search';

document.addEventListener('DOMContentLoaded', () => {
  Project.initRefSwitcher(); // Code Search Branch Picker
  setHighlightClass(); // Code Search Highlighting
  refreshCounts(); // Other Scope Tab Counts
  initSearchApp(); // Vue Bootstrap
});
