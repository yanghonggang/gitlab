# frozen_string_literal: true

require 'spec_helper'

# Based on ee/spec/requests/api/epics_spec.rb
# Should follow closely in order to ensure all situations are covered
RSpec.describe 'Epics through GroupQuery' do
  include GraphqlHelpers

  let(:user)       { create(:user) }
  let(:group)      { create(:group) }
  let(:project)    { create(:project, :public, group: group) }
  let(:label)      { create(:label) }
  let(:epic)       { create(:labeled_epic, group: group, labels: [label]) }
  let(:epics_data) { graphql_data['group']['epics']['edges'] }
  let(:epic_data)  { graphql_data['group']['epic'] }

  # similar to GET /groups/:id/epics
  describe 'Get list of epics from a group' do
    let(:epic_node) do
      <<~NODE
        edges {
          node {
            id
            iid
            title
            upvotes
            downvotes
            userPermissions {
              adminEpic
            }
          }
        }
      NODE
    end

    def query(params = {})
      graphql_query_for("group", { "fullPath" => group.full_path },
                        ['epicsEnabled',
                         query_graphql_field("epics", params, epic_node)]
      )
    end

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)
        epic && group.reload

        post_graphql(query, current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns epics successfully' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to be_nil
        expect(epic_node_array('id').first).to eq epic.to_global_id.to_s
        expect(graphql_data['group']['epicsEnabled']).to be_truthy
      end
    end

    context 'with multiple epics' do
      let(:user2)  { create(:user) }
      let!(:epic)  { create(:epic, group: group, state: :closed, created_at: 3.days.ago, updated_at: 2.days.ago) }
      let!(:epic2) { create(:epic, author: user2, group: group, title: 'foo', description: 'bar', created_at: 2.days.ago, updated_at: 3.days.ago) }

      before do
        stub_licensed_features(epics: true)
      end

      it 'sorts by created_at descending by default' do
        post_graphql(query, current_user: user)

        expect_array_response([epic2.to_global_id.to_s, epic.to_global_id.to_s])
      end

      it 'has upvote/downvote information' do
        create(:award_emoji, name: 'thumbsup', awardable: epic, user: user )
        create(:award_emoji, name: 'thumbsdown', awardable: epic2, user: user )

        post_graphql(query, current_user: user)

        expect(epic_node_array).to contain_exactly(
          a_hash_including('upvotes' => 1, 'downvotes' => 0),
          a_hash_including('upvotes' => 0, 'downvotes' => 1)
        )
      end

      describe 'can admin epics' do
        context 'when permission is absent' do
          it 'returns false for adminEpic' do
            post_graphql(query, current_user: user)

            expect(epic_node_array('userPermissions')).to all(include('adminEpic' => false))
          end
        end

        context 'when permission is present' do
          before do
            group.add_maintainer(user)
          end

          it 'returns true for adminEpic' do
            post_graphql(query, current_user: user)

            expect(epic_node_array('userPermissions')).to all(include('adminEpic' => true))
          end
        end
      end

      context 'query performance' do
        let!(:child_epic) { create(:epic, group: group, parent: epic2) }
        let(:epic_node) do
          <<~NODE
            edges {
              node {
                parent {
                  id
                }
              }
            }
          NODE
        end

        before do
          group.reload
          post_graphql(query, current_user: user)
        end

        it 'avoids n+1 queries when loading parent field' do
          control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            post_graphql(query, current_user: user)
          end.count

          epics_with_parent = create_list(:epic, 3, group: group) do |epic|
            epic.update(parent: create(:epic, group: group))
          end
          group.reload

          # Added +1 to control_count due to an existing N+1 with licenses
          expect do
            post_graphql(query({ iids: epics_with_parent.pluck(:iid) }), current_user: user)
          end.not_to exceed_all_query_limit(control_count + 1)
        end
      end
    end

    context 'when error requests' do
      context 'when epics feature is disabled' do
        it 'returns empty' do
          group.add_developer(user)

          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(epics_data).to be_empty
          expect(graphql_data['group']['epicsEnabled']).to be_falsey
        end

        context 'when epics feature is enabled' do
          before do
            stub_licensed_features(epics: true)
          end

          it 'returns a nil group for a user without permissions to see the group' do
            project.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
            group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

            post_graphql(query, current_user: user)

            expect(response).to have_gitlab_http_status(:success)
            expect(graphql_errors).to be_nil
            expect(graphql_data['group']).to be_nil
          end
        end
      end
    end
  end

  # similar to 'GET /groups/:id/epics/:epic_iid'
  describe 'Get epic from a group' do
    let(:query) do
      graphql_query_for('group', { 'fullPath' => group.full_path },
                        ['epicsEnabled',
                         query_graphql_field('epic', { iid: epic.iid })]
      )
    end

    context 'when the request is correct' do
      before do
        stub_licensed_features(epics: true)

        post_graphql(query)
      end

      it_behaves_like 'a working graphql query'

      it 'returns an epic successfully' do
        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_nil
        expect(epic_data['id']).to eq epic.to_global_id.to_s
        expect(graphql_data['group']['epicsEnabled']).to be_truthy
        expect(epic_data['confidential']).to be_falsey
      end
    end
  end

  describe 'N+1 query checks' do
    let(:epic_a) { create(:epic, group: group) }
    let(:epic_b) { create(:epic, group: group) }
    let(:epics) { [epic_a, epic_b] }
    let(:extra_iid_for_second_query) { epic_b.iid.to_s }
    let(:search_params) { { iids: [epic_a.iid.to_s] } }

    def execute_query
      query = graphql_query_for(
        :group,
        { full_path: group.full_path },
        query_graphql_field(:epics, search_params, [
          query_graphql_field(:nodes, nil, requested_fields)
        ])
      )
      post_graphql(query, current_user: user)
    end

    context 'when requesting `user_notes_count`' do
      let(:requested_fields) { [:user_notes_count] }

      before do
        create_list(:note_on_epic, 2, noteable: epic_a)
        create(:note_on_epic, noteable: epic_b)
      end

      include_examples 'N+1 query check'
    end

    context 'when requesting `user_discussions_count`' do
      let(:requested_fields) { [:user_discussions_count] }

      before do
        create_list(:note_on_epic, 2, noteable: epic_a)
        create(:note_on_epic, noteable: epic_b)
      end

      include_examples 'N+1 query check'
    end
  end

  def expect_array_response(items)
    expect(response).to have_gitlab_http_status(:success)
    expect(epics_data).to be_an Array
    expect(epic_node_array('id')).to eq(Array(items))
  end

  def epic_node_array(extract_attribute = nil)
    node_array(epics_data, extract_attribute)
  end
end
