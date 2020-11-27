# frozen_string_literal: true

module HasWikiPageSlugAttributes
  extend ActiveSupport::Concern

  included do
    validates :slug, presence: true, uniqueness: { scope: foreign_key }
    validates :canonical, uniqueness: {
          scope: foreign_key,
          if: :canonical?,
          message: 'Only one slug can be canonical per wiki metadata record'
    }

    scope :canonical, -> { where(canonical: true) }

    def update_columns(attrs = {})
      super(attrs.reverse_merge(updated_at: Time.current.utc))
    end
  end

  def self.update_all(attrs = {})
    super(attrs.reverse_merge(updated_at: Time.current.utc))
  end
end
