import { GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Component from 'ee/vue_shared/security_reports/components/event_item.vue';
import NoteHeader from '~/notes/components/note_header.vue';

describe('Event Item', () => {
  let wrapper;

  const mountComponent = (options, mountFn = shallowMount) => {
    wrapper = mountFn(Component, options);
  };

  const noteHeader = () => wrapper.find(NoteHeader);

  describe('initial state', () => {
    const propsData = {
      id: 123,
      createdAt: 'createdAt',
      headerMessage: 'header message',
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
    };

    const slots = { default: '<p>Test</p>' };

    beforeEach(() => {
      mountComponent({ propsData, slots });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('passes the expected values to the note header component', () => {
      expect(noteHeader().props()).toMatchObject({
        noteId: propsData.id,
        author: propsData.author,
        createdAt: propsData.createdAt,
        showSpinner: false,
      });
    });

    it('uses the fallback icon', () => {
      expect(wrapper.props().iconName).toBe('plus');
    });

    it('uses the fallback icon class', () => {
      expect(wrapper.props().iconClass).toBe('ci-status-icon-success');
    });

    it('renders the action buttons container', () => {
      expect(wrapper.find('.action-buttons')).toExist();
    });

    it('renders the default slot', () => {
      expect(wrapper.html()).toEqual(expect.stringContaining('<p>Test</p>'));
    });
  });
  describe('with action buttons', () => {
    const propsData = {
      author: {
        name: 'Tanuki',
        username: 'gitlab',
      },
      actionButtons: [
        {
          iconName: 'pencil',
          onClick: jest.fn(),
          title: 'Foo Action',
        },
        {
          iconName: 'remove',
          onClick: jest.fn(),
          title: 'Bar Action',
        },
      ],
    };

    afterEach(() => {
      wrapper.destroy();
    });

    beforeEach(() => {
      mountComponent({ propsData }, mount);
    });

    it('renders the action buttons container', () => {
      expect(wrapper.find('.action-buttons')).toExist();
    });

    it('renders the action buttons', () => {
      expect(wrapper.findAll(GlButton)).toHaveLength(2);
      expect(wrapper.element).toMatchSnapshot();
    });

    it('emits the button events when clicked', () => {
      const buttons = wrapper.findAll(GlButton);
      buttons.at(0).trigger('click');
      return wrapper.vm
        .$nextTick()
        .then(() => {
          buttons.at(1).trigger('click');
          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(propsData.actionButtons[0].onClick).toHaveBeenCalledTimes(1);
          expect(propsData.actionButtons[1].onClick).toHaveBeenCalledTimes(1);
        });
    });
  });
});
