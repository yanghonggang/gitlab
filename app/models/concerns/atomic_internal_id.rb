# frozen_string_literal: true

# Include atomic internal id generation scheme for a model
#
# This allows us to atomically generate internal ids that are
# unique within a given scope.
#
# For example, let's generate internal ids for Issue per Project:
# ```
# class Issue < ApplicationRecord
#   has_internal_id :iid, scope: :project, init: ->(s) { s.project.issues.maximum(:iid) }
# end
# ```
#
# This generates unique internal ids per project for newly created issues.
# The generated internal id is saved in the `iid` attribute of `Issue`.
#
# This concern uses InternalId records to facilitate atomicity.
# In the absence of a record for the given scope, one will be created automatically.
# In this situation, the `init` block is called to calculate the initial value.
# In the example above, we calculate the maximum `iid` of all issues
# within the given project.
#
# Note that a model may have more than one internal id associated with possibly
# different scopes.
module AtomicInternalId
  extend ActiveSupport::Concern

  class_methods do
    def has_internal_id( # rubocop:disable Naming/PredicateName
      column, scope:, init: :not_given, ensure_if: nil, track_if: nil,
      presence: true, backfill: false, hook_names: :create)
      raise "has_internal_id init must not be nil if given." if init.nil?
      raise "has_internal_id needs to be defined on association." unless self.reflect_on_association(scope)

      init = infer_init(scope) if init == :not_given
      before_validation :"track_#{scope}_#{column}!", on: hook_names, if: track_if
      before_validation :"ensure_#{scope}_#{column}!", on: hook_names, if: ensure_if
      validates column, presence: presence

      define_singleton_internal_id_methods(scope, column, init)
      define_instance_internal_id_methods(scope, column, init, backfill)
    end

    private

    def infer_init(scope)
      case scope
      when :project
        AtomicInternalId.project_init(self)
      when :group
        AtomicInternalId.group_init(self)
      else
        # We require init here to retain the ability to recalculate in the absence of a
        # InternalId record (we may delete records in `internal_ids` for example).
        raise "has_internal_id - cannot infer init for scope: #{scope}"
      end
    end

    # Defines instance methods:
    #   - ensure_{scope}_{column}!
    #   - track_{scope}_{column}!
    #   - reset_{scope}_{column}
    #   - {column}=
    def define_instance_internal_id_methods(scope, column, init, backfill)
      define_method("ensure_#{scope}_#{column}!") do
        return if backfill && self.class.where(column => nil).exists?

        scope_value = internal_id_read_scope(scope)
        value = read_attribute(column)
        return value unless scope_value

        if value.nil?
          # We don't have a value yet and use a InternalId record to generate
          # the next value.
          value = InternalId.generate_next(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            init)
          write_attribute(column, value)
        end

        value
      end

      define_method("track_#{scope}_#{column}!") do
        return unless @internal_id_needs_tracking

        scope_value = internal_id_read_scope(scope)
        return unless scope_value

        value = read_attribute(column)

        if value.present?
          # The value was set externally, e.g. by the user
          # We update the InternalId record to keep track of the greatest value.
          InternalId.track_greatest(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            value,
            init)

          @internal_id_needs_tracking = false
        end
      end

      define_method("#{column}=") do |value|
        super(value).tap do |v|
          # Indicate the iid was set from externally
          @internal_id_needs_tracking = true
        end
      end

      define_method("reset_#{scope}_#{column}") do
        if value = read_attribute(column)
          did_reset = InternalId.reset(
            self,
            internal_id_scope_attrs(scope),
            internal_id_scope_usage,
            value)

          if did_reset
            write_attribute(column, nil)
          end
        end

        read_attribute(column)
      end
    end

    # Defines class methods:
    #
    # - with_{scope}_{column}_supply
    #   This method can be used to allocate a block of IID values during
    #   bulk operations (importing/copying, etc). This can be more efficient
    #   than creating instances one-by-one.
    #
    #   Pass in a block that receives a `Supply` instance. To allocate a new
    #   IID value, call `Supply#next_value`.
    #
    #   Example:
    #
    #   MyClass.with_project_iid_supply(project) do |supply|
    #     attributes = MyClass.where(project: project).find_each do |record|
    #       record.attributes.merge(iid: supply.next_value)
    #     end
    #
    #     bulk_insert(attributes)
    #   end
    def define_singleton_internal_id_methods(scope, column, init)
      define_singleton_method("with_#{scope}_#{column}_supply") do |scope_value, &block|
        subject = find_by(scope => scope_value) || self
        scope_attrs = ::AtomicInternalId.scope_attrs(scope_value)
        usage = ::AtomicInternalId.scope_usage(self)

        generator = InternalId::InternalIdGenerator.new(subject, scope_attrs, usage, init)

        generator.with_lock do
          supply = Supply.new(generator.record.last_value)
          block.call(supply)
        ensure
          generator.track_greatest(supply.current_value) if supply
        end
      end
    end
  end

  def self.scope_attrs(scope_value)
    { scope_value.class.table_name.singularize.to_sym => scope_value } if scope_value
  end

  def internal_id_scope_attrs(scope)
    scope_value = internal_id_read_scope(scope)

    ::AtomicInternalId.scope_attrs(scope_value)
  end

  def internal_id_scope_usage
    ::AtomicInternalId.scope_usage(self.class)
  end

  def self.scope_usage(including_class)
    including_class.table_name.to_sym
  end

  def self.project_init(klass, column_name = :iid)
    ->(instance, scope) do
      if instance
        klass.where(project_id: instance.project_id).maximum(column_name)
      elsif scope.present?
        klass.where(**scope).maximum(column_name)
      end
    end
  end

  def self.group_init(klass, column_name = :iid)
    ->(instance, scope) do
      if instance
        klass.where(group_id: instance.group_id).maximum(column_name)
      elsif scope.present?
        klass.where(group: scope[:namespace]).maximum(column_name)
      end
    end
  end

  def internal_id_read_scope(scope)
    association(scope).reader
  end

  class Supply
    attr_reader :current_value

    def initialize(start_value)
      @current_value = start_value
    end

    def next_value
      @current_value += 1
    end
  end
end
