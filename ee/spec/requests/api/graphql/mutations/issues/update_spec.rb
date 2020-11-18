# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing issue' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let(:input) do
    {
      'iid' => issue.iid.to_s,
      'weight' => 2,
      'healthStatus' => 'atRisk'
    }
  end

  let(:mutation) { graphql_mutation(:update_issue, input.merge(project_path: project.full_path)) }
  let(:mutated_issue) { graphql_mutation_response(:update_issue)['issue'] }

  before do
    stub_licensed_features(issuable_health_status: true)
    project.add_developer(current_user)
  end

  it 'updates the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutated_issue).to include(input)
  end

  context 'setting epic' do
    let(:epic) { create(:epic, group: group) }

    let(:input) do
      { iid: issue.iid.to_s, epic_id: global_id_of(epic) }
    end

    before do
      stub_licensed_features(epics: true)
      group.add_developer(current_user)
    end

    it 'sets the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_blank
      expect(mutated_issue).to include(
        'epic' => include('id' => global_id_of(epic))
      )
    end

    context 'the epic is not readable to the current user' do
      let(:epic) { create(:epic) }

      it 'does not set the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).not_to be_blank
      end
    end

    context 'the epic is not an epic' do
      let(:epic) { create(:user) }

      it 'does not set the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).not_to be_blank
      end
    end

    # TODO: remove when the global-ID compatibility layer is removed,
    # at which point this error becomes unreachable because the query will
    # be rejected as ill-typed.
    context 'the epic is not an epic, using the ID type' do
      let(:mutation) do
        query = <<~GQL
        mutation($epic: ID!, $path: ID!, $iid: String!) {
          updateIssue(input: { epicId: $epic, projectPath: $path, iid: $iid }) {
            errors
          }
        }
        GQL

        ::GraphqlHelpers::MutationDefinition.new(query, {
          epic: global_id_of(create(:user)),
          iid: issue.iid.to_s,
          path: project.full_path
        })
      end

      it 'does not set the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to contain_exactly(
          a_hash_including('message' => /No object found/)
        )
      end
    end
  end

  context 'removing epic' do
    let(:epic) { create(:epic, group: group) }

    let(:input) do
      { iid: issue.iid.to_s, epic_id: nil }
    end

    before do
      stub_licensed_features(epics: true)
      group.add_developer(current_user)
      issue.update!(epic: epic)
    end

    it 'removes the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_blank
      expect(mutated_issue).to include('epic' => be_nil)
    end

    context 'the epic argument is not provided' do
      let(:input) do
        { iid: issue.iid.to_s, weight: 1 }
      end

      it 'does not remove the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_blank
        expect(mutated_issue).to include('epic' => be_present)
      end
    end
  end
end
