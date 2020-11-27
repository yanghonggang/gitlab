import { mount, shallowMount } from '@vue/test-utils';
import ExpandableSection from 'ee/security_configuration/sast/components/expandable_section.vue';

describe('ExpandableSection component', () => {
  let wrapper;

  const createComponent = (options, mountFn = shallowMount) => {
    wrapper = mountFn(ExpandableSection, options);
  };

  const findButton = () => wrapper.find('button');
  const findHeading = () => wrapper.find('[data-testid="heading"]');
  const findSubHeading = () => wrapper.find('[data-testid="sub-heading"]');
  const findContent = () => wrapper.find('[data-testid="content"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('headingTag', () => {
    it('defaults to h3', () => {
      createComponent();

      expect(findHeading().element.tagName).toBe('H3');
    });

    it('uses the given the heading tag name', () => {
      const headingTag = 'h6';

      createComponent({
        propsData: { headingTag },
      });

      expect(findHeading().element.tagName).toBe(headingTag.toUpperCase());
    });
  });

  describe('heading slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { heading: 'some heading' },
      });
    });

    it('renders the given heading content', () => {
      expect(findHeading().html()).toContain('some heading');
    });
  });

  describe('subheading slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { 'sub-heading': 'some subheading' },
      });
    });

    it('renders the given subheading content', () => {
      expect(findSubHeading().html()).toContain('some subheading');
    });
  });

  describe('default slot', () => {
    beforeEach(() => {
      createComponent({
        slots: { default: 'some content' },
      });
    });

    it('renders the given content', () => {
      expect(findContent().html()).toContain('some content');
    });
  });

  describe('expand/collapse behavior', () => {
    beforeEach(() => {
      createComponent({}, mount);
    });

    it('hides the content by default', () => {
      expect(findContent().isVisible()).toBe(false);
    });

    it('shows an expand button', () => {
      expect(findButton().text()).toBe('Expand');
    });

    describe('clicking the expand button', () => {
      beforeEach(() => {
        const button = findButton();
        button.trigger('click');
        return wrapper.vm.$nextTick();
      });

      it('shows the content', () => {
        expect(findContent().isVisible()).toBe(true);
      });

      it('shows a collapse button', () => {
        expect(findButton().text()).toBe('Collapse');
      });
    });
  });
});
