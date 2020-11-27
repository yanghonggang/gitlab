import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import groupItemComponent from '~/groups/components/group_item.vue';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import { getGroupItemMicrodata } from '~/groups/store/utils';
import eventHub from '~/groups/event_hub';
import * as urlUtilities from '~/lib/utils/url_utility';
import { mockParentGroupItem, mockChildren } from '../mock_data';

const createComponent = (group = mockParentGroupItem, parentGroup = mockChildren[0]) => {
  const Component = Vue.extend(groupItemComponent);

  return mountComponent(Component, {
    group,
    parentGroup,
  });
};

describe('GroupItemComponent', () => {
  let vm;

  beforeEach(() => {
    Vue.component('group-folder', groupFolderComponent);

    vm = createComponent();

    return Vue.nextTick();
  });

  afterEach(() => {
    vm.$destroy();
  });

  const withMicrodata = group => ({
    ...group,
    microdata: getGroupItemMicrodata(group),
  });

  describe('computed', () => {
    describe('groupDomId', () => {
      it('should return ID string suffixed with group ID', () => {
        expect(vm.groupDomId).toBe('group-55');
      });
    });

    describe('rowClass', () => {
      it('should return map of classes based on group details', () => {
        const classes = ['is-open', 'has-children', 'has-description', 'being-removed'];
        const { rowClass } = vm;

        expect(Object.keys(rowClass).length).toBe(classes.length);
        Object.keys(rowClass).forEach(className => {
          expect(classes.indexOf(className)).toBeGreaterThan(-1);
        });
      });
    });

    describe('hasChildren', () => {
      it('should return boolean value representing if group has any children present', () => {
        let newVm;
        const group = { ...mockParentGroupItem };

        group.childrenCount = 5;
        newVm = createComponent(group);

        expect(newVm.hasChildren).toBeTruthy();
        newVm.$destroy();

        group.childrenCount = 0;
        newVm = createComponent(group);

        expect(newVm.hasChildren).toBeFalsy();
        newVm.$destroy();
      });
    });

    describe('hasAvatar', () => {
      it('should return boolean value representing if group has any avatar present', () => {
        let newVm;
        const group = { ...mockParentGroupItem };

        group.avatarUrl = null;
        newVm = createComponent(group);

        expect(newVm.hasAvatar).toBeFalsy();
        newVm.$destroy();

        group.avatarUrl = '/uploads/group_avatar.png';
        newVm = createComponent(group);

        expect(newVm.hasAvatar).toBeTruthy();
        newVm.$destroy();
      });
    });

    describe('isGroup', () => {
      it('should return boolean value representing if group item is of type `group` or not', () => {
        let newVm;
        const group = { ...mockParentGroupItem };

        group.type = 'group';
        newVm = createComponent(group);

        expect(newVm.isGroup).toBeTruthy();
        newVm.$destroy();

        group.type = 'project';
        newVm = createComponent(group);

        expect(newVm.isGroup).toBeFalsy();
        newVm.$destroy();
      });
    });
  });

  describe('methods', () => {
    describe('onClickRowGroup', () => {
      let event;

      beforeEach(() => {
        const classList = {
          contains() {
            return false;
          },
        };

        event = {
          target: {
            classList,
            parentElement: {
              classList,
            },
          },
        };
      });

      it('should emit `toggleChildren` event when expand is clicked on a group and it has children present', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        vm.onClickRowGroup(event);

        expect(eventHub.$emit).toHaveBeenCalledWith('toggleChildren', vm.group);
      });

      it('should navigate page to group homepage if group does not have any children present', () => {
        jest.spyOn(urlUtilities, 'visitUrl').mockImplementation();
        const group = { ...mockParentGroupItem };
        group.childrenCount = 0;
        const newVm = createComponent(group);
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        newVm.onClickRowGroup(event);

        expect(eventHub.$emit).not.toHaveBeenCalled();
        expect(urlUtilities.visitUrl).toHaveBeenCalledWith(newVm.group.relativePath);
      });
    });
  });

  describe('template', () => {
    let group = null;

    describe('for a group pending deletion', () => {
      beforeEach(() => {
        group = { ...mockParentGroupItem, pendingRemoval: true };
        vm = createComponent(group);
      });

      it('renders the group pending removal badge', () => {
        const badgeEl = vm.$el.querySelector('.badge-warning');

        expect(badgeEl).toBeDefined();
        expect(badgeEl.innerHTML).toContain('pending removal');
      });
    });

    describe('for a group not scheduled for deletion', () => {
      beforeEach(() => {
        group = { ...mockParentGroupItem, pendingRemoval: false };
        vm = createComponent(group);
      });

      it('does not render the group pending removal badge', () => {
        const groupTextContainer = vm.$el.querySelector('.group-text-container');

        expect(groupTextContainer).not.toContain('pending removal');
      });
    });

    it('should render component template correctly', () => {
      const visibilityIconEl = vm.$el.querySelector('.item-visibility');

      expect(vm.$el.getAttribute('id')).toBe('group-55');
      expect(vm.$el.classList.contains('group-row')).toBeTruthy();

      expect(vm.$el.querySelector('.group-row-contents')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .controls')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .stats')).toBeDefined();

      expect(vm.$el.querySelector('.folder-toggle-wrap')).toBeDefined();
      expect(vm.$el.querySelector('.folder-toggle-wrap .folder-caret')).toBeDefined();
      expect(vm.$el.querySelector('.folder-toggle-wrap .item-type-icon')).toBeDefined();

      expect(vm.$el.querySelector('.avatar-container')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container a.no-expand')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container .avatar')).toBeDefined();

      expect(vm.$el.querySelector('.title')).toBeDefined();
      expect(vm.$el.querySelector('.title a.no-expand')).toBeDefined();

      expect(visibilityIconEl).not.toBe(null);
      expect(visibilityIconEl.title).toBe(vm.visibilityTooltip);
      expect(visibilityIconEl.querySelectorAll('svg').length).toBeGreaterThan(0);

      expect(vm.$el.querySelector('.access-type')).toBeDefined();
      expect(vm.$el.querySelector('.description')).toBeDefined();

      expect(vm.$el.querySelector('.group-list-tree')).toBeDefined();
    });
  });
  describe('schema.org props', () => {
    describe('when showSchemaMarkup is disabled on the group', () => {
      it.each(['itemprop', 'itemtype', 'itemscope'], 'it does not set %s', attr => {
        expect(vm.$el.getAttribute(attr)).toBeNull();
      });
      it.each(
        ['.js-group-avatar', '.js-group-name', '.js-group-description'],
        'it does not set `itemprop` on sub-nodes',
        selector => {
          expect(vm.$el.querySelector(selector).getAttribute('itemprop')).toBeNull();
        },
      );
    });
    describe('when group has microdata', () => {
      beforeEach(() => {
        const group = withMicrodata({
          ...mockParentGroupItem,
          avatarUrl: 'http://foo.bar',
          description: 'Foo Bar',
        });

        vm = createComponent(group);
      });

      it.each`
        attr           | value
        ${'itemscope'} | ${'itemscope'}
        ${'itemtype'}  | ${'https://schema.org/Organization'}
        ${'itemprop'}  | ${'subOrganization'}
      `('it does set correct $attr', ({ attr, value } = {}) => {
        expect(vm.$el.getAttribute(attr)).toBe(value);
      });

      it.each`
        selector                               | propValue
        ${'[data-testid="group-avatar"]'}      | ${'logo'}
        ${'[data-testid="group-name"]'}        | ${'name'}
        ${'[data-testid="group-description"]'} | ${'description'}
      `('it does set correct $selector', ({ selector, propValue } = {}) => {
        expect(vm.$el.querySelector(selector).getAttribute('itemprop')).toBe(propValue);
      });
    });
  });
});
