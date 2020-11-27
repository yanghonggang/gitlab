# frozen_string_literal: true

module GroupWikiPage
  class Slug < ApplicationRecord
    self.table_name = 'group_wiki_page_slugs'

    belongs_to :group_wiki_page_meta, class_name: 'GroupWikiPage::Meta', inverse_of: :slugs

    validates :slug, presence: true, uniqueness: { scope: :group_wiki_page_meta_id }
    validates :canonical, uniqueness: {
          scope: :group_wiki_page_meta_id,
          if: :canonical?,
          message: 'Only one slug can be canonical per wiki metadata record'
    }

    scope :canonical, -> { where(canonical: true) }

    def update_columns(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.current.utc))
    end

    def self.update_all(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.current.utc))
    end
  end
end
