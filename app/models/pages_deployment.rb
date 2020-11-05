# frozen_string_literal: true

# PagesDeployment stores a zip archive containing GitLab Pages web-site
class PagesDeployment < ApplicationRecord
  include FileStoreMounter

  belongs_to :project, optional: false
  belongs_to :ci_build, class_name: 'Ci::Build', optional: true

  validates :file, presence: true
  validates :file_store, presence: true, inclusion: { in: ObjectStorage::SUPPORTED_STORES }
  validates :size, presence: true, numericality: { greater_than: 0, only_integer: true }

  before_validation :set_size, if: :file_changed?

  default_value_for(:file_store) { ::Pages::DeploymentUploader.default_store }

  mount_file_store_uploader ::Pages::DeploymentUploader

  private

  def set_size
    self.size = file.size
  end
end
