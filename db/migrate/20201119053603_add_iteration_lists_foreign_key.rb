# frozen_string_literal: true

class AddIterationListsForeignKey < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :lists, :iteration_id
    add_concurrent_foreign_key :lists, :sprints, column: :iteration_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :lists, :sprints, column: :iteration_id
    remove_concurrent_index :lists, :iteration_id
  end
end
