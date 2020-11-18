import { GlIcon, GlPopover, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RemediatedBadge from 'ee/vulnerabilities/components/remediated_badge.vue';

const POPOVER_TITLE = 'Vulnerability remediated. Review before resolving.';
const POPOVER_CONTENT =
  'The vulnerability is no longer detected. Verify the vulnerability has been fixed or removed before changing its status.';

describe('Remediated badge component', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findBadge = () => wrapper.find(GlBadge);

  const createWrapper = () => {
    return shallowMount(RemediatedBadge);
  };

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => wrapper.destroy());

  it('should display the correct icon', () => {
    expect(findIcon().props('name')).toBe('admin');
  });

  it('should link the badge and the popover', () => {
    const popover = wrapper.find({ ref: 'popover' });
    expect(popover.props('target')()).toEqual(findBadge().element);
  });

  it('should pass down the data to the popover', () => {
    const popoverAttributes = wrapper.find(GlPopover).attributes();

    expect(popoverAttributes.title).toEqual(POPOVER_TITLE);
    expect(popoverAttributes.content).toEqual(POPOVER_CONTENT);
  });
});
