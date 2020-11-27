import { GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import StateTooltip from 'ee/related_items_tree/components/state_tooltip.vue';

// Ensure that mock dates dynamically computed from today
// so that test doesn't fail at any point in time.
const currentDate = new Date();
const mockCreatedAt = `${currentDate.getFullYear() - 2}-${currentDate.getMonth() +
  1}-${currentDate.getDate()}`;
const mockCreatedAtYear = currentDate.getFullYear() - 2;
const mockClosedAt = `${currentDate.getFullYear() - 1}-${currentDate.getMonth() +
  1}-${currentDate.getDate()}`;
const mockClosedAtYear = currentDate.getFullYear() - 1;

const createComponent = ({
  getTargetRef = () => {},
  isOpen = false,
  path = '/foo/bar#1',
  state = 'closed',
  createdAt = mockCreatedAt,
  closedAt = mockClosedAt,
}) =>
  shallowMount(StateTooltip, {
    propsData: {
      getTargetRef,
      isOpen,
      path,
      state,
      createdAt,
      closedAt,
    },
  });

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeHeader', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent({});
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('stateText', () => {
        it('returns string `Opened` when `isOpen` prop is true', () => {
          wrapper.setProps({
            isOpen: true,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Opened');
          });
        });

        it('returns string `Closed` when `isOpen` prop is false', () => {
          wrapper.setProps({
            isOpen: false,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateText).toBe('Closed');
          });
        });
      });

      describe('createdAtInWords', () => {
        it('returns string containing date in words for `createdAt` prop', () => {
          expect(wrapper.vm.createdAtInWords).toBe('2 years ago');
        });
      });

      describe('closedAtInWords', () => {
        it('returns string containing date in words for `closedAt` prop', () => {
          expect(wrapper.vm.closedAtInWords).toBe('1 year ago');
        });
      });

      describe('createdAtTimestamp', () => {
        it('returns string containing date timestamp for `createdAt` prop', () => {
          expect(wrapper.vm.createdAtTimestamp).toContain(mockCreatedAtYear);
        });
      });

      describe('closedAtTimestamp', () => {
        it('returns string containing date timestamp for `closedAt` prop', () => {
          expect(wrapper.vm.closedAtTimestamp).toContain(mockClosedAtYear);
        });
      });

      describe('stateTimeInWords', () => {
        it('returns string using `createdAtInWords` prop when `isOpen` is true', () => {
          wrapper.setProps({
            isOpen: true,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateTimeInWords).toBe('2 years ago');
          });
        });

        it('returns string using `closedAtInWords` prop when `isOpen` is false', () => {
          wrapper.setProps({
            isOpen: false,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateTimeInWords).toBe('1 year ago');
          });
        });
      });

      describe('stateTimestamp', () => {
        it('returns string using `createdAtTimestamp` prop when `isOpen` is true', () => {
          wrapper.setProps({
            isOpen: true,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateTimestamp).toContain(mockCreatedAtYear);
          });
        });

        it('returns string using `closedAtInWords` prop when `isOpen` is false', () => {
          wrapper.setProps({
            isOpen: false,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.stateTimestamp).toContain(mockClosedAtYear);
          });
        });
      });
    });

    describe('methods', () => {
      describe('getTimestamp', () => {
        it('returns timestamp string from rawTimestamp', () => {
          expect(wrapper.vm.getTimestamp(mockClosedAt)).toContain(mockClosedAtYear);
        });
      });

      describe('getTimestampInWords', () => {
        it('returns string date in words from rawTimestamp', () => {
          expect(wrapper.vm.getTimestampInWords(mockClosedAt)).toContain('1 year ago');
        });
      });
    });

    describe('template', () => {
      it('renders gl-tooltip as container element', () => {
        expect(wrapper.find(GlTooltip).isVisible()).toBe(true);
      });

      it('renders path in bold', () => {
        expect(
          wrapper
            .find({ ref: 'statePath' })
            .text()
            .trim(),
        ).toBe('/foo/bar#1');
      });

      it('renders stateText in bold', () => {
        expect(
          wrapper
            .find({ ref: 'stateText' })
            .text()
            .trim(),
        ).toBe('Closed');
      });

      it('renders stateTimeInWords', () => {
        expect(wrapper.text().trim()).toContain('1 year ago');
      });

      it('renders stateTimestamp in muted', () => {
        expect(
          wrapper
            .find({ ref: 'stateTimestamp' })
            .text()
            .trim(),
        ).toContain(mockClosedAtYear);
      });
    });
  });
});
