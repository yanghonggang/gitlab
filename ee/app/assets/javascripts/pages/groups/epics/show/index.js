import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import EpicTabs from 'ee/epic/epic_tabs';
import initEpicApp from 'ee/epic/epic_bundle';
import ZenMode from '~/zen_mode';
import '~/notes/index';
import loadAwardsHandler from '~/awards_handler';

new ZenMode(); // eslint-disable-line no-new
initEpicApp();
new ShortcutsEpic(); // eslint-disable-line no-new
new EpicTabs(); // eslint-disable-line no-new
loadAwardsHandler();
