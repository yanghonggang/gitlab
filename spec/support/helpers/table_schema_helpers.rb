# frozen_string_literal: true

module TableSchemaHelpers
  def connection
    ActiveRecord::Base.connection
  end

  def expect_table_to_be_replaced(original_table:, replacement_table:, archived_table:)
    original_oid = table_oid(original_table)
    replacement_oid = table_oid(replacement_table)

    yield

    expect(table_oid(original_table)).to eq(replacement_oid)
    expect(table_oid(archived_table)).to eq(original_oid)
    expect(table_oid(replacement_table)).to be_nil
  end

  def expect_index_to_exist(name, schema: nil)
    expect(index_exists_by_name(name, schema: schema)).to eq(true)
  end

  def expect_index_not_to_exist(name, schema: nil)
    expect(index_exists_by_name(name, schema: schema)).to be_nil
  end

  def table_oid(name)
    connection.select_value(<<~SQL)
      SELECT oid
      FROM pg_catalog.pg_class
      WHERE relname = '#{name}'
    SQL
  end

  def table_type(name)
    connection.select_value(<<~SQL)
      SELECT
        CASE class.relkind
        WHEN 'r' THEN 'normal'
        WHEN 'p' THEN 'partitioned'
        ELSE 'other'
        END as table_type
      FROM pg_catalog.pg_class class
      WHERE class.relname = '#{name}'
    SQL
  end

  def sequence_owned_by(table_name, column_name)
    connection.select_value(<<~SQL)
      SELECT
        sequence.relname as name
      FROM pg_catalog.pg_class as sequence
      INNER JOIN pg_catalog.pg_depend depend
        ON depend.objid = sequence.oid
      INNER JOIN pg_catalog.pg_class class
        ON class.oid = depend.refobjid
      INNER JOIN pg_catalog.pg_attribute attribute
        ON attribute.attnum = depend.refobjsubid
        AND attribute.attrelid = depend.refobjid
      WHERE class.relname = '#{table_name}'
        AND attribute.attname = '#{column_name}'
    SQL
  end

  def default_expression_for(table_name, column_name)
    connection.select_value(<<~SQL)
      SELECT
        pg_get_expr(attrdef.adbin, attrdef.adrelid) AS default_value
      FROM pg_catalog.pg_attribute attribute
      INNER JOIN pg_catalog.pg_attrdef attrdef
        ON attribute.attrelid = attrdef.adrelid
        AND attribute.attnum = attrdef.adnum
      WHERE attribute.attrelid = '#{table_name}'::regclass
        AND attribute.attname = '#{column_name}'
    SQL
  end

  def primary_key_constraint_name(table_name)
    connection.select_value(<<~SQL)
      SELECT
        conname AS constraint_name
      FROM pg_catalog.pg_constraint
      WHERE conrelid = '#{table_name}'::regclass
        AND contype = 'p'
    SQL
  end

  def index_exists_by_name(index, schema: nil)
    schema = schema ? "'#{schema}'" : 'current_schema'

    connection.select_value(<<~SQL)
      SELECT true
      FROM pg_catalog.pg_index i
      INNER JOIN pg_catalog.pg_class c
        ON c.oid = i.indexrelid
      INNER JOIN pg_catalog.pg_namespace n
        ON c.relnamespace = n.oid
      WHERE c.relname = '#{index}'
        AND n.nspname = #{schema}
    SQL
  end
end
