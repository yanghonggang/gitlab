/* eslint-disable func-names, no-return-assign */

import $ from 'jquery';
import Cookies from 'js-cookie';
import { __ } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { serializeForm } from '~/lib/utils/forms';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as flash } from '~/flash';
import projectSelect from '../../project_select';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default class Project {
  constructor() {
    const $cloneOptions = $('ul.clone-options-dropdown');
    if ($cloneOptions.length) {
      const $projectCloneField = $('#project_clone');
      const $cloneBtnLabel = $('.js-git-clone-holder .js-clone-dropdown-label');
      const mobileCloneField = document.querySelector(
        '.js-mobile-git-clone .js-clone-dropdown-label',
      );

      const selectedCloneOption = $cloneBtnLabel.text().trim();
      if (selectedCloneOption.length > 0) {
        $(`a:contains('${selectedCloneOption}')`, $cloneOptions).addClass('is-active');
      }

      $('a', $cloneOptions).on('click', e => {
        e.preventDefault();
        const $this = $(e.currentTarget);
        const url = $this.attr('href');
        const cloneType = $this.data('cloneType');

        $('.is-active', $cloneOptions).removeClass('is-active');
        $(`a[data-clone-type="${cloneType}"]`).each(function() {
          const $el = $(this);
          const activeText = $el.find('.dropdown-menu-inner-title').text();
          const $container = $el.closest('.project-clone-holder');
          const $label = $container.find('.js-clone-dropdown-label');

          $el.toggleClass('is-active');
          $label.text(activeText);
        });

        if (mobileCloneField) {
          mobileCloneField.dataset.clipboardText = url;
        } else {
          $projectCloneField.val(url);
        }
        $('.js-git-empty .js-clone').text(url);
      });
    }

    // Ref switcher
    if (document.querySelector('.js-project-refs-dropdown')) {
      Project.initRefSwitcher();
      $('.project-refs-select').on('change', function() {
        return $(this)
          .parents('form')
          .trigger('submit');
      });
    }

    $('.hide-no-ssh-message').on('click', function(e) {
      Cookies.set('hide_no_ssh_message', 'false');
      $(this)
        .parents('.no-ssh-key-message')
        .remove();
      return e.preventDefault();
    });
    $('.hide-no-password-message').on('click', function(e) {
      Cookies.set('hide_no_password_message', 'false');
      $(this)
        .parents('.no-password-message')
        .remove();
      return e.preventDefault();
    });
    $('.hide-auto-devops-implicitly-enabled-banner').on('click', function(e) {
      const projectId = $(this).data('project-id');
      const cookieKey = `hide_auto_devops_implicitly_enabled_banner_${projectId}`;
      Cookies.set(cookieKey, 'false');
      $(this)
        .parents('.auto-devops-implicitly-enabled-banner')
        .remove();
      return e.preventDefault();
    });

    Project.projectSelectDropdown();
  }

  static projectSelectDropdown() {
    projectSelect();
    $('.project-item-select').on('click', e => Project.changeProject($(e.currentTarget).val()));
  }

  static changeProject(url) {
    return (window.location = url);
  }

  static initRefSwitcher() {
    const refListItem = document.createElement('li');
    const refLink = document.createElement('a');

    refLink.href = '#';

    return $('.js-project-refs-dropdown').each(function() {
      const $dropdown = $(this);
      const selected = $dropdown.data('selected');
      const fieldName = $dropdown.data('fieldName');
      const shouldVisit = Boolean($dropdown.data('visit'));
      const $form = $dropdown.closest('form');
      const action = $form.attr('action');
      const linkTarget = mergeUrlParams(serializeForm($form[0]), action);

      return initDeprecatedJQueryDropdown($dropdown, {
        data(term, callback) {
          axios
            .get($dropdown.data('refsUrl'), {
              params: {
                ref: $dropdown.data('ref'),
                search: term,
              },
            })
            .then(({ data }) => callback(data))
            .catch(() => flash(__('An error occurred while getting projects')));
        },
        selectable: true,
        filterable: true,
        filterRemote: true,
        filterByText: true,
        inputFieldName: $dropdown.data('inputFieldName'),
        fieldName,
        renderRow(ref) {
          const li = refListItem.cloneNode(false);

          const link = refLink.cloneNode(false);

          if (ref === selected) {
            link.className = 'is-active';
          }
          link.textContent = ref;
          link.dataset.ref = ref;
          if (ref.length > 0 && shouldVisit) {
            link.href = mergeUrlParams({ [fieldName]: ref }, linkTarget);
          }

          li.appendChild(link);

          return li;
        },
        id(obj, $el) {
          return $el.attr('data-ref');
        },
        toggleLabel(obj, $el) {
          return $el.text().trim();
        },
        clicked(options) {
          const { e } = options;
          e.preventDefault();

          // Since this page does not reload when changing directories in a repo
          // the rendered links do not have the path to the current directory.
          // This updates the path based on the current url and then opens
          // the the url with the updated path parameter.
          if (shouldVisit) {
            const selectedUrl = new URL(e.target.href);
            const loc = window.location.href;

            if (loc.includes('/-/')) {
              const refs = this.fullData.Branches.concat(this.fullData.Tags);
              const currentRef = refs.find(ref => loc.indexOf(ref) > -1);
              if (currentRef) {
                const targetPath = loc.split(currentRef)[1].slice(1);
                selectedUrl.searchParams.set('path', targetPath);
              }
            }

            // Open in new window if "meta" key is pressed
            if (e.metaKey) {
              window.open(selectedUrl.href, '_blank');
            } else {
              window.location.href = selectedUrl.href;
            }
          }
        },
      });
    });
  }
}
