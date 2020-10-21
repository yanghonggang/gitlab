# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::AuthFilterExtension do
  let_it_be(:test_schema) do
    base_field = Class.new(::GraphQL::Schema::Field) do
      def initialize(*args, **kwargs, &block)
        super
        extension ::Gitlab::Graphql::AuthFilterExtension
      end
    end

    base_object = Class.new(::GraphQL::Schema::Object) do
      field_class base_field

      def self.authorized?(object, context)
        return false if object.is_a?(Hash) && object[:id] == 100

        true
      end
    end

    y_type = Class.new(base_object) do
      graphql_name 'Y'
      field :id, Integer, null: false

      def id
        object[:id]
      end
    end

    x_type = Class.new(base_object) do
      graphql_name 'X'
      field :title, String, null: true
      field :lazy_list_of_ys, [y_type], null: true
      field :list_of_lazy_ys, [y_type], null: true

      def lazy_list_of_ys
        ::Gitlab::Graphql::Lazy.new { object[:ys] }
      end

      def list_of_lazy_ys
        object[:ys].map { |y| ::Gitlab::Graphql::Lazy.new { y } }
      end
    end

    Class.new(GraphQL::Schema) do
      lazy_resolve ::Gitlab::Graphql::Lazy, :force

      query(Class.new(::Types::BaseObject) do
        graphql_name 'Query'
        field :x, x_type, null: true

        def x
          ::Gitlab::Graphql::Lazy.new { context[:x] }
        end
      end)

      def unauthorized_object(err)
        err.context.skip
      end
    end
  end

  def document(field)
    GraphQL.parse(<<~GQL)
    query {
      x {
        title
        #{field} { id }
      }
    }
    GQL
  end

  let(:data) do
    {
      x: {
        title: 'Hey',
        ys: [{ id: 1 }, { id: 100 }, { id: 2 }]
      }
    }
  end

  shared_examples 'array member redaction' do |field|
    it 'redacts the unauthorized array member' do
      query = GraphQL::Query.new(test_schema, document: document(field), context: data)
      result = query.result.to_h

      expect(result.dig('data', 'x', 'title')).to eq('Hey')
      expect(result.dig('data', 'x', field)).to contain_exactly(
        eq({ 'id' => 1 }),
        eq({ 'id' => 2 })
      )
    end
  end

  # For example a batchloaded association
  context 'a lazy list' do
    it_behaves_like 'array member redaction', 'lazyListOfYs'
  end

  # For example using a batchloader to map over a set of IDs
  context 'a list of lazy items' do
    it_behaves_like 'array member redaction', 'listOfLazyYs'
  end
end
