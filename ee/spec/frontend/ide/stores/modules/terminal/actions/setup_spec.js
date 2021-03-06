import testAction from 'helpers/vuex_action_helper';
import * as mutationTypes from 'ee/ide/stores/modules/terminal/mutation_types';
import * as actions from 'ee/ide/stores/modules/terminal/actions/setup';

describe('EE IDE store terminal setup actions', () => {
  describe('init', () => {
    it('dispatches checks', () => {
      return testAction(
        actions.init,
        null,
        {},
        [],
        [{ type: 'fetchConfigCheck' }, { type: 'fetchRunnersCheck' }],
      );
    });
  });

  describe('hideSplash', () => {
    it('commits HIDE_SPLASH', () => {
      return testAction(actions.hideSplash, null, {}, [{ type: mutationTypes.HIDE_SPLASH }], []);
    });
  });

  describe('setPaths', () => {
    it('commits SET_PATHS', () => {
      const paths = {
        foo: 'bar',
        lorem: 'ipsum',
      };

      return testAction(
        actions.setPaths,
        paths,
        {},
        [{ type: mutationTypes.SET_PATHS, payload: paths }],
        [],
      );
    });
  });
});
