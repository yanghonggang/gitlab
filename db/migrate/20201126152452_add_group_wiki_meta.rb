# frozen_string_literal: true

class AddGroupWikiMeta < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :group_wiki_page_meta, id: :serial do |t|
      t.references :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.text :title, null: false
    end

    create_table :group_wiki_page_slugs, id: :serial do |t|
      t.boolean :canonical, default: false, null: false
      t.references :group_wiki_page_meta, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.text :slug, null: false
      t.index [:slug, :group_wiki_page_meta_id], unique: true
      t.index [:group_wiki_page_meta_id], name: 'one_canonical_group_wiki_page_slug_per_metadata', unique: true, where: "(canonical = true)"
    end

    add_text_limit :group_wiki_page_meta, :title, 255
    add_text_limit :group_wiki_page_slugs, :slug, 2048
  end
end
