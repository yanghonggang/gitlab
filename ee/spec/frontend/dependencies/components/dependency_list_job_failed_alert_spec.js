import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DependencyListJobFailedAlert from 'ee/dependencies/components/dependency_list_job_failed_alert.vue';

const NO_BUTTON_PROPS = {
  secondaryButtonText: '',
  secondaryButtonLink: '',
};

describe('DependencyListJobFailedAlert component', () => {
  let wrapper;

  const factory = (options = {}) => {
    wrapper = shallowMount(DependencyListJobFailedAlert, {
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('matches the snapshot', () => {
    factory({ propsData: { jobPath: '/jobs/foo/3210' } });
    expect(wrapper.element).toMatchSnapshot();
  });

  it('inludes a button if "jobPath" is given', () => {
    const jobPath = '/jobs/foo/3210';
    factory({ propsData: { jobPath } });

    expect(wrapper.find(GlAlert).props()).toMatchObject({
      secondaryButtonText: 'View job',
      secondaryButtonLink: jobPath,
    });
  });

  it('does not include a button if "jobPath" is not given', () => {
    factory();

    expect(wrapper.find(GlAlert).props()).toMatchObject(NO_BUTTON_PROPS);
  });

  it.each([undefined, null, ''])(
    'does not include a button if "jobPath" is given but empty',
    jobPath => {
      factory({ propsData: { jobPath } });

      expect(wrapper.find(GlAlert).props()).toMatchObject(NO_BUTTON_PROPS);
    },
  );

  describe('when the GlAlert component emits a dismiss event', () => {
    let dismissListenerSpy;

    beforeEach(() => {
      dismissListenerSpy = jest.fn();

      factory({
        listeners: {
          dismiss: dismissListenerSpy,
        },
      });

      wrapper.find(GlAlert).vm.$emit('dismiss');
    });

    it('calls the given listener', () => {
      expect(dismissListenerSpy).toHaveBeenCalledTimes(1);
    });
  });
});
