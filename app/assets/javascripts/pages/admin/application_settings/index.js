import initSettingsPanels from '~/settings_panels';
import projectSelect from '~/project_select';
import selfMonitor from '~/self_monitor';
import { initMaintenanceModeSettings } from '~/maintenance_mode_settings';
import initVariableList from '~/ci_variable_list';

document.addEventListener('DOMContentLoaded', () => {
  if (gon.features?.ciInstanceVariablesUi) {
    initVariableList('js-instance-variables');
  }
  selfMonitor();
  initMaintenanceModeSettings();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectSelect();
});
