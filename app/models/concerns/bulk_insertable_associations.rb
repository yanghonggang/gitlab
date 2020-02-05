# frozen_string_literal: true

module BulkInsertableAssociations
  extend ActiveSupport::Concern
  extend self

  MissingAssociationError = Class.new(StandardError)

  class_methods do
    def bulk_insert_on_save(association, items)
      unless BulkInsertableAssociations.supports_bulk_insert?(self, association)
        raise "#{association} does not support bulk inserts"
      end

      pending_association_items = BulkInsertableAssociations.bulk_insert_context_for(self)
      pending_association_items[association] ||= []
      pending_association_items[association] += items
    end
  end

  included do
    delegate :bulk_insert_on_save, to: self
    after_save { BulkInsertableAssociations.flush_pending_bulk_inserts(self.class) }
  end

  def supports_bulk_insert?(model_class, association)
    association_class_for(model_class, association) < BulkInsertSafe
  end

  def bulk_insert_context_for(model_class)
    bulk_insert_context[model_class] ||= {}
  end

  def flush_pending_bulk_inserts(model_class)
    pending_association_items = bulk_insert_context_for(model_class)
    return unless pending_association_items&.any?

    pending_association_items.each do |association, items|
      items.each { |item| item.delete('id') unless item['id'] }
      association_class = association_class_for(model_class, association)
      association_class.insert_all(items, returning: ['id'])
    end
  ensure
    clear_bulk_insert_context_for(model_class)
  end

  private

  def association_class_for(model_class, association)
    reflection = model_class.reflect_on_association(association)
    unless reflection
      raise MissingAssociationError.new("#{model_class} does not define association #{association}")
    end

    reflection.klass
  end

  def bulk_insert_context
    Thread.current['_bulk_insert_context'] ||= {}
  end

  def clear_bulk_insert_context_for(model_class)
    bulk_insert_context.delete(model_class)
  end
end
