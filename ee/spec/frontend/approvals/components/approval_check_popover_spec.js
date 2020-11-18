import { GlPopover, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import component from 'ee/approvals/components/approval_check_popover.vue';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(component, {
      propsData: {
        title: 'Title',
      },
    });
  });

  describe('with a documentation link', () => {
    const documentationLink = `${TEST_HOST}/documentation`;
    beforeEach(done => {
      wrapper.setProps({
        documentationLink,
      });
      Vue.nextTick(done);
    });

    it('should render the documentation link', () => {
      expect(
        wrapper
          .find(GlPopover)
          .find(GlLink)
          .attributes('href'),
      ).toBe(documentationLink);
    });
  });

  describe('without a documentation link', () => {
    it('should not render the documentation link', () => {
      expect(
        wrapper
          .find(GlPopover)
          .find(GlLink)
          .exists(),
      ).toBeFalsy();
    });
  });
});
