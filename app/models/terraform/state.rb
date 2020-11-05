# frozen_string_literal: true

module Terraform
  class State < ApplicationRecord
    include UsageStatistics
    include FileStoreMounter
    include IgnorableColumns
    # These columns are being removed since geo replication falls to the versioned state
    # Tracking in https://gitlab.com/gitlab-org/gitlab/-/issues/258262
    ignore_columns %i[verification_failure verification_retry_at verified_at verification_retry_count verification_checksum],
                   remove_with: '13.7',
                   remove_after: '2020-12-22'

    HEX_REGEXP = %r{\A\h+\z}.freeze
    UUID_LENGTH = 32

    belongs_to :project
    belongs_to :locked_by_user, class_name: 'User'

    has_many :versions, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id
    has_one :latest_version, -> { ordered_by_version_desc }, class_name: 'Terraform::StateVersion', foreign_key: :terraform_state_id

    scope :versioning_not_enabled, -> { where(versioning_enabled: false) }
    scope :ordered_by_name, -> { order(:name) }

    validates :project_id, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { SecureRandom.hex(UUID_LENGTH / 2) }
    default_value_for(:versioning_enabled, true)

    mount_file_store_uploader StateUploader

    def file_store
      super || StateUploader.default_store
    end

    def latest_file
      if versioning_enabled?
        latest_version&.file
      else
        latest_version&.file || file
      end
    end

    def locked?
      self.lock_xid.present?
    end

    def update_file!(data, version:)
      if versioning_enabled?
        create_new_version!(data: data, version: version)
      elsif latest_version.present?
        migrate_legacy_version!(data: data, version: version)
      else
        self.file = data
        save!
      end
    end

    private

    ##
    # If a Terraform state was created before versioning support was
    # introduced, it will have a single version record whose file
    # uses a legacy naming scheme in object storage. To update
    # these states and versions to use the new behaviour, we must do
    # the following when creating the next version:
    #
    #  * Read the current, non-versioned file from the old location.
    #  * Update the :versioning_enabled flag, which determines the
    #    naming scheme
    #  * Resave the existing file with the updated name and location,
    #    using a version number one prior to the new version
    #  * Create the new version as normal
    #
    # This migration only needs to happen once for each state, from
    # then on the state will behave as if it was always versioned.
    #
    # The code can be removed in the next major version (14.0), after
    # which any states that haven't been migrated will need to be
    # recreated: https://gitlab.com/gitlab-org/gitlab/-/issues/258960
    def migrate_legacy_version!(data:, version:)
      current_file = latest_version.file.read
      current_version = parse_serial(current_file) || version - 1

      update!(versioning_enabled: true)

      reload_latest_version.update!(version: current_version, file: CarrierWaveStringFile.new(current_file))
      create_new_version!(data: data, version: version)
    end

    def create_new_version!(data:, version:)
      new_version = versions.build(version: version, created_by_user: locked_by_user)
      new_version.assign_attributes(file: data)
      new_version.save!
    end

    def parse_serial(file)
      Gitlab::Json.parse(file)["serial"]
    rescue JSON::ParserError
    end
  end
end
