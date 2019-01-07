import $ from 'jquery';
import Stats from 'ee/stats';

export default function initExportCSVModal() {
  const $modal = $('.issues-export-modal');
  const $downloadBtn = $('.csv_download_link');
  const $closeBtn = $('.modal-header .close');

  Stats.bindTrackableContainer('.issues-export-modal');

  $modal.modal({ show: false });
  $downloadBtn.on('click', () => $modal.modal('show'));
  $closeBtn.on('click', () => $modal.modal('hide'));
}
