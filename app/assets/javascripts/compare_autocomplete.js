/* eslint-disable func-names */

import $ from 'jquery';
import { __ } from './locale';
import axios from './lib/utils/axios_utils';
import { deprecatedCreateFlash as flash } from './flash';
import { capitalizeFirstCharacter } from './lib/utils/text_utility';
import { fixTitle } from '~/tooltips';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default function initCompareAutocomplete(limitTo = null, clickHandler = () => {}) {
  $('.js-compare-dropdown').each(function() {
    const $dropdown = $(this);
    const selected = $dropdown.data('selected');
    const $dropdownContainer = $dropdown.closest('.dropdown');
    const $fieldInput = $(`input[name="${$dropdown.data('fieldName')}"]`, $dropdownContainer);
    const $filterInput = $('input[type="search"]', $dropdownContainer);
    initDeprecatedJQueryDropdown($dropdown, {
      data(term, callback) {
        const params = {
          ref: $dropdown.data('ref'),
          search: term,
        };

        if (limitTo) {
          params.find = limitTo;
        }

        axios
          .get($dropdown.data('refsUrl'), {
            params,
          })
          .then(({ data }) => {
            if (limitTo) {
              callback(data[capitalizeFirstCharacter(limitTo)] || []);
            } else {
              callback(data);
            }
          })
          .catch(() => flash(__('Error fetching refs')));
      },
      selectable: true,
      filterable: true,
      filterRemote: Boolean($dropdown.data('refsUrl')),
      fieldName: $dropdown.data('fieldName'),
      filterInput: 'input[type="search"]',
      renderRow(ref) {
        const link = $('<a />')
          .attr('href', '#')
          .addClass(ref === selected ? 'is-active' : '')
          .text(ref)
          .attr('data-ref', ref);
        if (ref.header != null) {
          return $('<li />')
            .addClass('dropdown-header')
            .text(ref.header);
        }
        return $('<li />').append(link);
      },
      id(obj, $el) {
        return $el.attr('data-ref');
      },
      toggleLabel(obj, $el) {
        return $el.text().trim();
      },
      clicked: () => clickHandler($dropdown),
    });
    $filterInput.on('keyup', e => {
      const keyCode = e.keyCode || e.which;
      if (keyCode !== 13) return;
      const text = $filterInput.val();
      $fieldInput.val(text);
      $('.dropdown-toggle-text', $dropdown).text(text);
      $dropdownContainer.removeClass('open');
    });

    $dropdownContainer.on('click', '.dropdown-content a', e => {
      $dropdown.prop('title', e.target.text.replace(/_+?/g, '-'));
      if ($dropdown.hasClass('has-tooltip')) {
        fixTitle($dropdown);
      }
    });
  });
}
