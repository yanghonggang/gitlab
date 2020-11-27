import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import MetricsReportsIssueBody from 'ee/vue_shared/metrics_reports/components/metrics_reports_issue_body.vue';
import GroupedMetricsReportsApp from 'ee/vue_shared/metrics_reports/grouped_metrics_reports_app.vue';
import { getStoreConfig } from 'ee/vue_shared/metrics_reports/store';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Grouped metrics reports app', () => {
  let wrapper;
  let mockStore;

  const mountComponent = () => {
    wrapper = mount(GroupedMetricsReportsApp, {
      store: mockStore,
      localVue,
      propsData: {
        endpoint: 'metrics.json',
      },
      methods: {
        fetchMetrics: () => {},
      },
    });
  };

  beforeEach(() => {
    mockStore = new Vuex.Store(getStoreConfig());
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mockStore.state.isLoading = true;
      mountComponent();
    });

    it('renders loading state', () => {
      const header = wrapper.element.querySelector('.js-code-text');

      expect(header.innerText.trim()).toEqual('Metrics reports are loading');
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mockStore.state.isLoading = false;
      mockStore.state.hasError = true;
      mountComponent();
    });

    it('renders error state', () => {
      const header = wrapper.element.querySelector('.js-code-text');

      expect(header.innerText.trim()).toEqual('Metrics reports failed loading results');
    });
  });

  describe('with metrics', () => {
    describe('with no changes', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 0;
        mockStore.state.existingMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders no changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports did not change');
      });
    });

    describe('with one change', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.existingMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders one change header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('with multiple changes', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 2;
        mockStore.state.existingMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders multiple changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 2 points');
      });
    });

    describe('with new metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.newMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders new changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('with removed metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.removedMetrics = [
          {
            name: 'name',
            value: 'value',
          },
        ];
        mountComponent();
      });

      it('renders new changes header', () => {
        const header = wrapper.element.querySelector('.js-code-text');

        expect(header.innerText.trim()).toContain('Metrics reports changed on 1 point');
      });
    });

    describe('when has metrics', () => {
      beforeEach(() => {
        mockStore.state.numberOfChanges = 1;
        mockStore.state.existingMetrics = [
          {
            name: 'name',
            value: 'value',
            previous_value: 'prev',
          },
        ];
        mountComponent();
      });

      it('renders custom metric issue body', () => {
        const issueBody = wrapper.find(MetricsReportsIssueBody);

        expect(issueBody.props('issue').name).toEqual('name');
        expect(issueBody.props('issue').value).toEqual('value');
        expect(issueBody.props('issue').previous_value).toEqual('prev');
      });
    });
  });
});
