import initSecurityCharts from 'ee/security_dashboard/security_charts_init';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { TEST_HOST } from 'jest/helpers/test_constants';

const EMPTY_DIV = document.createElement('div');

const TEST_DATASET = {
  link: '/test/link',
  svgPath: '/test/no_changes_state.svg',
  dashboardDocumentation: '/test/dashboard_page',
  emptyStateSvgPath: '/test/empty_state.svg',
};

describe('Security Charts', () => {
  let vm;
  let root;

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);

    global.jsdom.reconfigure({
      url: `${TEST_HOST}/-/security/dashboard`,
    });
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
    vm = null;
    root.remove();
  });

  const createComponent = ({ data, type }) => {
    const el = document.createElement('div');
    Object.assign(el.dataset, { ...TEST_DATASET, ...data });
    root.appendChild(el);
    vm = initSecurityCharts(el, type);
  };

  const createEmptyComponent = () => {
    vm = initSecurityCharts(null, null);
  };

  describe('default states', () => {
    it('sets up group-level', () => {
      createComponent({ data: { groupFullPath: '/test/' }, type: DASHBOARD_TYPES.GROUP });

      expect(root).toMatchSnapshot();
    });

    it('sets up instance-level', () => {
      createComponent({
        data: { instanceDashboardSettingsPath: '/instance/settings_page' },
        type: DASHBOARD_TYPES.INSTANCE,
      });

      expect(root).toMatchSnapshot();
    });
  });

  describe('error states', () => {
    it('does not have an element', () => {
      createEmptyComponent();

      expect(root).toStrictEqual(EMPTY_DIV);
    });

    it('has unavailable pages', () => {
      createComponent({ data: { isUnavailable: true } });

      expect(root).toMatchSnapshot();
    });
  });
});
