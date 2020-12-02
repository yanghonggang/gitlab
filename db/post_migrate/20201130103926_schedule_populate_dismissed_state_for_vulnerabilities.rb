# frozen_string_literal: true

class SchedulePopulateDismissedStateForVulnerabilities < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  DELAY_INTERVAL = 3.minutes.to_i
  MIGRATION_CLASS = 'PopulateDismissedStateForVulnerabilities'

  disable_ddl_transaction!

  def up
    vulnerabilities = Gitlab::BackgroundMigration::PopulateDismissedStateForVulnerabilities.vulnerability_ids_with_invalid_state

    return if vulnerabilities.blank?

    vulnerabilities.rows.flatten.in_groups_of(BATCH_SIZE, false).each_with_index do |vulnerability_ids, index|
      migrate_in((index + 1) * DELAY_INTERVAL, MIGRATION_CLASS, vulnerability_ids)
    end
  end

  def down
    # no-op
  end
end
