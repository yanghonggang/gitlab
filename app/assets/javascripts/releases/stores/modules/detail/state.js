export default ({
  projectId,
  projectPath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,
  manageMilestonesPath,
  newMilestonePath,
  releasesPagePath,

  tagName = null,
  defaultBranch = null,
}) => ({
  projectId,
  projectPath,
  markdownDocsPath,
  markdownPreviewPath,
  updateReleaseApiDocsPath,
  releaseAssetsDocsPath,
  manageMilestonesPath,
  newMilestonePath,
  releasesPagePath,

  /**
   * The name of the tag associated with the release, provided by the backend.
   * When creating a new release, this value is null.
   */
  tagName,

  defaultBranch,
  createFrom: defaultBranch,

  /** The Release object */
  release: null,

  /**
   * A deep clone of the Release object above.
   * Used when editing this Release so that
   * changes can be computed.
   */
  originalRelease: null,

  isFetchingRelease: false,
  fetchError: null,

  isUpdatingRelease: false,
  updateError: null,
});
