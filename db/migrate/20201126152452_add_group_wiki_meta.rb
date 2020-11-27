# frozen_string_literal: true

class AddGroupWikiMeta < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :group_wiki_page_meta, id: :serial do |t|
      t.references :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.string :title, null: false, limit: 255
    end

    create_table :group_wiki_page_slugs, id: :serial do |t|
      t.boolean :canonical, default: false, null: false
      t.references :group_wiki_page_meta, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.timestamps_with_timezone null: false
      t.string :slug, null: false, limit: 2048
      t.index [:slug, :group_wiki_page_meta_id], unique: true
      t.index [:group_wiki_page_meta_id], name: 'one_canonical_group_wiki_page_slug_per_metadata', unique: true, where: "(canonical = true)"
    end
  end
end
