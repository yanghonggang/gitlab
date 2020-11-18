import { shallowMount } from '@vue/test-utils';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card.vue';
import { s__ } from '~/locale';

describe('Solution Card', () => {
  const solution = 'Upgrade to XYZ';
  const remediation = { summary: 'Update to 123', fixes: [], diff: 'SGVsbG8gR2l0TGFi' };

  let wrapper;

  const findSolutionText = () => wrapper.find({ ref: 'solution-text' });
  const findSolutionTitle = () => wrapper.find('h3');

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMount(SolutionCard, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with solution', () => {
    beforeEach(() => {
      createComponent({ propsData: { solution } });
    });

    it('renders the solution title', () => {
      expect(findSolutionTitle().text()).toBe('Solution');
    });

    it('renders the solution text', () => {
      expect(findSolutionText().text()).toBe(solution);
    });
  });

  describe('with remediation', () => {
    beforeEach(() => {
      createComponent({ propsData: { remediation, hasRemediation: true } });
    });

    it('renders the solution text', () => {
      expect(findSolutionText().text()).toBe(remediation.summary);
    });

    describe('with download patch', () => {
      beforeEach(() => {
        wrapper.setProps({ hasDownload: true });
        return wrapper.vm.$nextTick();
      });

      it('renders the create a merge request to implement this solution message', () => {
        expect(findSolutionText().text()).toContain(
          s__(
            'ciReport|Create a merge request to implement this solution, or download and apply the patch manually.',
          ),
        );
      });
    });

    describe('without download patch', () => {
      it('does not render the create a merge request to implement this solution message', () => {
        expect(findSolutionText().text()).not.toContain(
          s__(
            'ciReport|Create a merge request to implement this solution, or download and apply the patch manually.',
          ),
        );
      });
    });
  });
});
