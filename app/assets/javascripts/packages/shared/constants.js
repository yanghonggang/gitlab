import { __ } from '~/locale';

export const PackageType = {
  CONAN: 'conan',
  MAVEN: 'maven',
  NPM: 'npm',
  NUGET: 'nuget',
  PYPI: 'pypi',
  COMPOSER: 'composer',
  GENERIC: 'generic',
};

export const TrackingActions = {
  DELETE_PACKAGE: 'delete_package',
  REQUEST_DELETE_PACKAGE: 'request_delete_package',
  CANCEL_DELETE_PACKAGE: 'cancel_delete_package',
  PULL_PACKAGE: 'pull_package',
};

export const TrackingCategories = {
  [PackageType.MAVEN]: 'MavenPackages',
  [PackageType.NPM]: 'NpmPackages',
  [PackageType.CONAN]: 'ConanPackages',
};

export const SHOW_DELETE_SUCCESS_ALERT = 'showSuccessDeleteAlert';
export const DELETE_PACKAGE_ERROR_MESSAGE = __('Something went wrong while deleting the package.');
