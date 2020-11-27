/* eslint-disable consistent-return */

import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { addDelimiter } from './lib/utils/text_utility';
import { deprecatedCreateFlash as flash } from './flash';
import CreateMergeRequestDropdown from './create_merge_request_dropdown';
import IssuablesHelper from './helpers/issuables_helper';
import { joinPaths } from '~/lib/utils/url_utility';
import { __ } from './locale';

export default class Issue {
  constructor() {
    if ($('.btn-close, .btn-reopen').length) this.initIssueBtnEventListeners();

    if ($('.js-close-blocked-issue-warning').length) this.initIssueWarningBtnEventListener();

    if ($('.js-alert-moved-from-service-desk-warning').length) {
      const trimmedPathname = window.location.pathname.slice(1);
      this.alertMovedFromServiceDeskDismissedKey = joinPaths(
        trimmedPathname,
        'alert-issue-moved-from-service-desk-dismissed',
      );

      this.initIssueMovedFromServiceDeskDismissHandler();
    }

    Issue.$btnNewBranch = $('#new-branch');
    Issue.createMrDropdownWrap = document.querySelector('.create-mr-dropdown-wrap');

    if (document.querySelector('#related-branches')) {
      Issue.initRelatedBranches();
    }

    this.closeButtons = $('.btn-close');
    this.reopenButtons = $('.btn-reopen');

    this.initCloseReopenReport();

    if (Issue.createMrDropdownWrap) {
      this.createMergeRequestDropdown = new CreateMergeRequestDropdown(Issue.createMrDropdownWrap);
    }

    // Listen to state changes in the Vue app
    document.addEventListener('issuable_vue_app:change', event => {
      this.updateTopState(event.detail.isClosed, event.detail.data);
    });
  }

  /**
   * This method updates the top area of the issue.
   *
   * Once the issue state changes, either through a click on the top area (jquery)
   * or a click on the bottom area (Vue) we need to update the top area.
   *
   * @param {Boolean} isClosed
   * @param {Array} data
   * @param {String} issueFailMessage
   */
  updateTopState(
    isClosed,
    data,
    issueFailMessage = __('Unable to update this issue at this time.'),
  ) {
    if ('id' in data) {
      const isClosedBadge = $('div.status-box-issue-closed');
      const isOpenBadge = $('div.status-box-open');
      const projectIssuesCounter = $('.issue_counter');

      isClosedBadge.toggleClass('hidden', !isClosed);
      isOpenBadge.toggleClass('hidden', isClosed);

      $(document).trigger('issuable:change', isClosed);
      this.toggleCloseReopenButton(isClosed);

      let numProjectIssues = Number(
        projectIssuesCounter
          .first()
          .text()
          .trim()
          .replace(/[^\d]/, ''),
      );
      numProjectIssues = isClosed ? numProjectIssues - 1 : numProjectIssues + 1;
      projectIssuesCounter.text(addDelimiter(numProjectIssues));

      if (this.createMergeRequestDropdown) {
        this.createMergeRequestDropdown.checkAbilityToCreateBranch();
      }
    } else {
      flash(issueFailMessage);
    }
  }

  initIssueBtnEventListeners() {
    const issueFailMessage = __('Unable to update this issue at this time.');

    $('.report-abuse-link').on('click', e => {
      // this is needed because of the implementation of
      // the dropdown toggle and Report Abuse needing to be
      // linked to another page.
      e.stopPropagation();
    });

    // NOTE: data attribute seems unnecessary but is actually necessary
    return $('.js-issuable-buttons[data-action="close-reopen"]').on(
      'click',
      '.btn-close, .btn-reopen, .btn-close-anyway',
      e => {
        e.preventDefault();
        e.stopImmediatePropagation();
        const $button = $(e.currentTarget);
        const shouldSubmit = $button.hasClass('btn-comment');
        if (shouldSubmit) {
          Issue.submitNoteForm($button.closest('form'));
        }

        const shouldDisplayBlockedWarning = $button.hasClass('btn-issue-blocked');
        const warningBanner = $('.js-close-blocked-issue-warning');
        if (shouldDisplayBlockedWarning) {
          this.toggleWarningAndCloseButton();
        } else {
          this.disableCloseReopenButton($button);

          const url = $button.data('endpoint');

          return axios
            .put(url)
            .then(({ data }) => {
              const isClosed = $button.is('.btn-close, .btn-close-anyway');
              this.updateTopState(isClosed, data);
              if ($button.hasClass('btn-close-anyway')) {
                warningBanner.addClass('hidden');
                if (this.closeReopenReportToggle)
                  $('.js-issuable-close-dropdown').removeClass('hidden');
              }
            })
            .catch(() => flash(issueFailMessage))
            .then(() => {
              this.disableCloseReopenButton($button, false);
            });
        }
      },
    );
  }

  initCloseReopenReport() {
    this.closeReopenReportToggle = IssuablesHelper.initCloseReopenReport();

    if (this.closeButtons) this.closeButtons = this.closeButtons.not('.issuable-close-button');
    if (this.reopenButtons) this.reopenButtons = this.reopenButtons.not('.issuable-close-button');
  }

  disableCloseReopenButton($button, shouldDisable) {
    if (this.closeReopenReportToggle) {
      this.closeReopenReportToggle.setDisable(shouldDisable);
    } else {
      $button.prop('disabled', shouldDisable);
    }
  }

  toggleCloseReopenButton(isClosed) {
    if (this.closeReopenReportToggle) this.closeReopenReportToggle.updateButton(isClosed);
    this.closeButtons.toggleClass('hidden', isClosed);
    this.reopenButtons.toggleClass('hidden', !isClosed);
  }

  toggleWarningAndCloseButton() {
    const warningBanner = $('.js-close-blocked-issue-warning');
    warningBanner.toggleClass('hidden');
    $('.btn-close').toggleClass('hidden');
    if (this.closeReopenReportToggle) {
      $('.js-issuable-close-dropdown').toggleClass('hidden');
    }
  }

  initIssueWarningBtnEventListener() {
    return $(document).on(
      'click',
      '.js-close-blocked-issue-warning .js-cancel-blocked-issue-warning',
      e => {
        e.preventDefault();
        e.stopImmediatePropagation();
        this.toggleWarningAndCloseButton();
      },
    );
  }

  initIssueMovedFromServiceDeskDismissHandler() {
    const alertMovedFromServiceDeskWarning = $('.js-alert-moved-from-service-desk-warning');

    if (!localStorage.getItem(this.alertMovedFromServiceDeskDismissedKey)) {
      alertMovedFromServiceDeskWarning.show();
    }

    alertMovedFromServiceDeskWarning.on('click', '.js-close', e => {
      e.preventDefault();
      e.stopImmediatePropagation();
      alertMovedFromServiceDeskWarning.remove();
      localStorage.setItem(this.alertMovedFromServiceDeskDismissedKey, true);
    });
  }

  static submitNoteForm(form) {
    const noteText = form.find('textarea.js-note-text').val();
    if (noteText && noteText.trim().length > 0) {
      return form.submit();
    }
  }

  static initRelatedBranches() {
    const $container = $('#related-branches');
    return axios
      .get($container.data('url'))
      .then(({ data }) => {
        if ('html' in data) {
          $container.html(data.html);
        }
      })
      .catch(() => flash(__('Failed to load related branches')));
  }
}
