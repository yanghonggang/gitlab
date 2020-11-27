# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Timelogs through GroupQuery' do
  include GraphqlHelpers

  describe 'Get list of timelogs from a group issues' do
    let_it_be(:user)      { create(:user) }
    let_it_be(:group)     { create(:group) }
    let_it_be(:project)   { create(:project, :public, group: group) }
    let_it_be(:milestone) { create(:milestone, group: group) }
    let_it_be(:epic)      { create(:epic, group: group) }
    let_it_be(:issue)     { create(:issue, project: project, milestone: milestone, epic: epic) }
    let_it_be(:timelog1)  { create(:timelog, issue: issue, user: user, spent_at: '2019-08-13 14:00:00') }
    let_it_be(:timelog2)  { create(:timelog, issue: issue, user: user, spent_at: '2019-08-10 08:00:00') }
    let_it_be(:params)    { { startTime: '2019-08-10 12:00:00', endTime: '2019-08-21 12:00:00' } }
    let(:timelogs_data)   { graphql_data['group']['timelogs']['nodes'] }

    before do
      group.add_developer(user)
      stub_licensed_features(group_timelogs: true, epics: true)
    end

    context 'when the request is correct' do
      before do
        post_graphql(query, current_user: user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns timelogs successfully' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(graphql_errors).to be_nil
        expect(timelog_array.size).to eq 1
        expect(graphql_data['group']['groupTimelogsEnabled']).to be_truthy
      end

      it 'contains correct data', :aggregate_failures do
        username = timelog_array.map {|data| data['user']['username'] }
        spent_at = timelog_array.map { |data| data['spentAt'].to_time }
        time_spent = timelog_array.map { |data| data['timeSpent'] }
        issue_title = timelog_array.map {|data| data['issue']['title'] }
        milestone_title = timelog_array.map {|data| data['issue']['milestone']['title'] }
        epic_title = timelog_array.map {|data| data['issue']['epic']['title'] }

        expect(username).to eq([user.username])
        expect(spent_at.first).to be_like_time(timelog1.spent_at)
        expect(time_spent).to eq([timelog1.time_spent])
        expect(issue_title).to eq([issue.title])
        expect(milestone_title).to eq([milestone.title])
        expect(epic_title).to eq([epic.title])
      end

      context 'when arguments with no time are present' do
        let!(:timelog3) { create(:timelog, issue: issue, user: user, spent_at: '2019-08-10 15:00:00') }
        let!(:timelog4) { create(:timelog, issue: issue, user: user, spent_at: '2019-08-21 15:00:00') }
        let(:params) { { startDate: '2019-08-10', endDate: '2019-08-21' }}

        it 'sets times as start of day and end of day' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(timelog_array.size).to eq 2
        end
      end
    end

    context 'when requests has errors' do
      context 'when group_timelogs feature is disabled' do
        before do
          stub_licensed_features(group_timelogs: false)
        end

        it 'returns empty' do
          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(timelogs_data).to be_empty
          expect(graphql_data['group']['groupTimelogsEnabled']).to be_falsey
        end
      end

      context 'when there are no timelogs present' do
        before do
          Timelog.delete_all
        end

        it 'returns empty result' do
          post_graphql(query, current_user: user)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(timelogs_data).to be_empty
          expect(graphql_data['group']['groupTimelogsEnabled']).to be_truthy
        end
      end

      context 'when user has no permission to read group timelogs' do
        it 'returns empty result' do
          guest = create(:user)
          group.add_guest(guest)
          post_graphql(query, current_user: guest)

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_errors).to be_nil
          expect(timelogs_data).to be_empty
          expect(graphql_data['group']['groupTimelogsEnabled']).to be_truthy
        end
      end
    end
  end

  def timelog_array(extract_attribute = nil)
    timelogs_data.map do |item|
      extract_attribute ? item[extract_attribute] : item
    end
  end

  def query(timelog_params = params)
    timelog_nodes = <<~NODE
      nodes {
        spentAt
        timeSpent
        user {
          username
        }
        issue {
          title
          milestone {
            title
          }
          epic {
            title
          }
        }
      }
    NODE

    graphql_query_for("group", { "fullPath" => group.full_path },
      ['groupTimelogsEnabled', query_graphql_field(
        "timelogs",
        timelog_params,
        timelog_nodes
      )]
    )
  end
end
