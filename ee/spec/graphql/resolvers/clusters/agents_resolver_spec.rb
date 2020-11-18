# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::AgentsResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Clusters::AgentType.connection_type)
  end

  specify do
    expect(described_class.field_options).to include(extras: include(:lookahead))
  end

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user, maintainer_projects: [project]) }
    let_it_be(:user) { create(:user, developer_projects: [project]) }
    let_it_be(:agents) { create_list(:cluster_agent, 2, project: project) }

    let(:ctx) { { current_user: current_user } }

    before do
      stub_licensed_features(cluster_agents: true)
    end

    subject { resolve_agents }

    context 'the current user has access to clusters' do
      let(:current_user) { maintainer }

      def select_tokens(result)
        result.to_a.map(&:agent_tokens)
      end

      it 'preloads agent tokens when needed', :request_store do
        expect { select_tokens(subject) }
          .to issue_same_number_of_queries_as { select_tokens(resolve_agents({ first: 1 })) }.or_fewer.ignoring_cached_queries
      end

      it 'finds all agents' do
        expect(subject).to match_array(agents)
      end

      it 'supports pagination' do
        expect(resolve_agents({ first: 1 }).to_a).to be_one
      end
    end

    context 'the current user does not have access to clusters' do
      let(:current_user) { user }

      it 'returns an empty result' do
        expect(subject).to be_empty
      end
    end
  end

  def resolve_agents(args = {})
    resolve(described_class, obj: project, ctx: ctx, lookahead: positive_lookahead, args: args)
  end
end

RSpec.describe Resolvers::Clusters::AgentsResolver.single do
  it { expect(described_class).to be < Resolvers::Clusters::AgentsResolver }

  describe '.field_options' do
    subject { described_class.field_options }

    specify do
      expect(subject).to include(
        type: ::Types::Clusters::AgentType,
        null: true,
        extras: [:lookahead]
      )
    end
  end

  describe 'arguments' do
    subject { described_class.arguments[argument] }

    describe 'name' do
      let(:argument) { 'name' }

      it do
        expect(subject).to be_present
        expect(subject.type.to_s).to eq('String!')
        expect(subject.description).to be_present
      end
    end
  end
end
