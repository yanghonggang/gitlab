import setHighlightClass from '~/search/highlight_blob_search_result';

export default () => {
  const highlightLineClass = 'hll';
  const contentBody = document.getElementById('content-body');
  const blobs = contentBody.querySelectorAll('.blob-result');

  // Supports Basic (backed by Gitaly) Search highlighting
  setHighlightClass();

  // Supports Advanced (backed by Elasticsearch) Search highlighting
  blobs.forEach(blob => {
    const lines = blob.querySelectorAll('.line');
    const dataHighlightLine = blob.querySelector('[data-highlight-line]');
    if (dataHighlightLine) {
      const { highlightLine } = dataHighlightLine.dataset;
      lines[highlightLine].classList.add(highlightLineClass);
    }
  });
};
