# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gets registries' do
  it_behaves_like 'gets registries for', {
    field_name: 'mergeRequestDiffRegistries',
    registry_class_name: 'MergeRequestDiffRegistry',
    registry_factory: :geo_merge_request_diff_registry,
    registry_foreign_key_field_name: 'mergeRequestDiffId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'packageFileRegistries',
    registry_class_name: 'PackageFileRegistry',
    registry_factory: :geo_package_file_registry,
    registry_foreign_key_field_name: 'packageFileId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'snippetRepositoryRegistries',
    registry_class_name: 'SnippetRepositoryRegistry',
    registry_factory: :geo_snippet_repository_registry,
    registry_foreign_key_field_name: 'snippetRepositoryId'
  }

  it_behaves_like 'gets registries for', {
    field_name: 'terraformStateVersionRegistries',
    registry_class_name: 'TerraformStateVersionRegistry',
    registry_factory: :geo_terraform_state_version_registry,
    registry_foreign_key_field_name: 'terraformStateVersionId'
  }
end
