# frozen_string_literal: true

require 'spec_helper'

# There must be a method or let called `mutation` defined that executes
# the mutation and one called `mutation_name` that is the name of the
# mutation being executed.
RSpec.shared_examples 'an on-demand scan mutation when user can run an on-demand scan' do
  let(:project) { create(:project, :repository, creator: current_user) }
  let(:current_user) { create(:user) }
  let(:full_path) { project.full_path }

  def mutation_response
    graphql_mutation_response(mutation_name)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  before do
    stub_licensed_features(security_on_demand_scans: true)
    project.add_developer(current_user)
  end

  it 'returns an empty errors array' do
    subject

    expect(mutation_response["errors"]).to be_empty
  end

  context 'when on demand scan licensed feature is not available' do
    before do
      stub_licensed_features(security_on_demand_scans: false)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end
end
