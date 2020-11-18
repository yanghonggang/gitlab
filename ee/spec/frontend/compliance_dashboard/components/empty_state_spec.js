import { shallowMount } from '@vue/test-utils';

import EmptyState from 'ee/compliance_dashboard/components/empty_state.vue';

const IMAGE_PATH = 'empty.svg';

describe('EmptyState component', () => {
  let wrapper;

  const findImage = () => wrapper.find('img');
  const findText = () => wrapper.find('.text-content');

  const createComponent = (props = {}) => {
    return shallowMount(EmptyState, {
      propsData: {
        imagePath: IMAGE_PATH,
        ...props,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('behaviour', () => {
    it('sets the empty SVG path', () => {
      expect(findImage().element.getAttribute('src')).toEqual(IMAGE_PATH);
    });

    it('renders a message', () => {
      expect(findText().text()).toEqual(
        "Includes completed merge requests. You haven't yet finished a merge request. View documentation",
      );
    });
  });
});
