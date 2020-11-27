import {
  GfmAutocompleteType,
  tributeConfig,
} from 'ee/vue_shared/components/gfm_autocomplete/utils';

describe('ee gfm_autocomplete/utils', () => {
  describe('epics config', () => {
    const epicsConfig = tributeConfig[GfmAutocompleteType.Epics].config;
    const epic = {
      id: null,
      iid: 123456,
      title: "Epic title <script>alert('hi')</script>",
    };

    it('uses & as the trigger', () => {
      expect(epicsConfig.trigger).toBe('&');
    });

    it('inserts the iid on autocomplete selection', () => {
      expect(epicsConfig.fillAttr).toBe('iid');
    });

    it('searches using both the iid and title', () => {
      expect(epicsConfig.lookup(epic)).toBe(`${epic.iid}${epic.title}`);
    });

    it('shows the iid and title in the menu item', () => {
      expect(epicsConfig.menuItemTemplate({ original: epic })).toMatchSnapshot();
    });
  });
});
