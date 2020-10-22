# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::BaseObject do
  describe 'scoping items' do
    let_it_be(:test_schema) do
      base_object = Class.new(described_class) do
        # Override authorization so we don't need to mock Ability
        def self.authorized?(object, context)
          return false if object == { id: 100 }
          return false if object.try(:deactivated?)

          true
        end
      end

      y_type = Class.new(base_object) do
        graphql_name 'Y'
        authorize :read_y
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

      user_type = Class.new(base_object) do
        graphql_name 'User'
        authorize :read_user
        field 'name', String, null: true
      end

      Class.new(GraphQL::Schema) do
        lazy_resolve ::Gitlab::Graphql::Lazy, :force
        use GraphQL::Pagination::Connections

        query(Class.new(::Types::BaseObject) do
          graphql_name 'Query'
          field :x, x_type, null: true
          field :users, user_type.connection_type, null: true

          def x
            ::Gitlab::Graphql::Lazy.new { context[:x] }
          end

          def users
            ::Gitlab::Graphql::Lazy.new { User.id_in(context[:user_ids]) }
          end
        end)

        def unauthorized_object(err)
          nil
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

    it 'filters connections correctly' do
      active_users = create_list(:user, 3, state: :active)
      inactive = create(:user, state: :deactivated)

      data = { user_ids: [inactive, *active_users].map(&:id) }

      doc = GraphQL.parse(<<~GQL)
      query {
        users { nodes { name } }
      }
      GQL

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      expect(result.dig('data', 'users', 'nodes')).to match_array(active_users.map do |u|
        eq({ 'name' => u.name })
      end)
    end

    it 'paginates before scoping' do
      # Inactive first so they sort first
      n = 3
      inactive = create_list(:user, n - 1, state: :deactivated)
      active_users = create_list(:user, 2, state: :active)

      data = { user_ids: [*inactive, *active_users].map(&:id) }

      doc = GraphQL.parse(<<~GQL)
      query {
        users(first: #{n}) {
          pageInfo { hasNextPage }
          nodes { name } }
      }
      GQL

      query = GraphQL::Query.new(test_schema, document: doc, context: data)
      result = query.result.to_h

      # We expect the page to be loaded and then filtered - i.e. to have all
      # deactivated users removed.
      expect(result.dig('data', 'users', 'pageInfo', 'hasNextPage')).to be_truthy
      expect(result.dig('data', 'users', 'nodes'))
        .to contain_exactly({ 'name' => active_users.first.name })
    end
  end
end
