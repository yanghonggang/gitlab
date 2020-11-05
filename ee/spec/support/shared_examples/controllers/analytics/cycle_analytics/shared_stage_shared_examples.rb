# frozen_string_literal: true

RSpec.shared_examples 'cycle analytics stages controller' do
  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #index' do
    subject { get :index, params: params }

    it 'succeeds' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('analytics/cycle_analytics/stages', dir: 'ee')
    end

    it 'returns correct start events' do
      subject

      response_start_events = json_response['stages'].map { |s| s['start_event_identifier'] }
      start_events = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map { |s| s['start_event_identifier'] }

      expect(response_start_events).to eq(start_events)
    end

    it 'does not include internal events' do
      subject

      response_event_names = json_response['events'].map { |s| s['name'] }
      event_names = Gitlab::Analytics::CycleAnalytics::StageEvents.events
      internal_events = Gitlab::Analytics::CycleAnalytics::StageEvents.internal_events
      expected_event_names = (event_names - internal_events).map(&:name)

      expect(response_event_names).to eq(expected_event_names.sort)
    end

    it 'succeeds for subgroups' do
      subgroup = create(:group, parent: group)
      params[:group_id] = subgroup.full_path
      params[:value_stream_id] = create(:cycle_analytics_group_value_stream, group: subgroup).id

      subject

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'renders `forbidden` based on the response of the service object' do
      expect_any_instance_of(Analytics::CycleAnalytics::Stages::ListService).to receive(:can?).and_return(false)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    include_examples 'group permission check on the controller level'
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    include_examples 'group permission check on the controller level'

    context 'when valid parameters are given' do
      before do
        params.merge!({
          name: 'my new stage',
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged
        })
      end

      it 'creates the stage' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('analytics/cycle_analytics/stage', dir: 'ee')
      end
    end

    include_context 'when invalid stage parameters are given'
  end

  describe 'PUT #update' do
    let(:stage) { create(:cycle_analytics_group_stage, parent: parent, relative_position: 15) }

    subject { put :update, params: params.merge(id: stage.id) }

    include_examples 'group permission check on the controller level'

    context 'when valid parameters are given' do
      before do
        params.merge!({
          name: 'my updated stage',
          start_event_identifier: :merge_request_created,
          end_event_identifier: :merge_request_merged
        })
      end

      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('analytics/cycle_analytics/stage', dir: 'ee')
      end

      it 'updates the name attribute' do
        subject

        stage.reload

        expect(stage.name).to eq(params[:name])
      end

      context 'hidden attribute' do
        before do
          params[:hidden] = true
        end

        it 'updates the hidden attribute' do
          subject

          stage.reload

          expect(stage.hidden).to eq(true)
        end
      end

      context 'when positioning parameter is given' do
        before do
          params[:move_before_id] = create(:cycle_analytics_group_stage, parent: group, relative_position: 10).id
        end

        it 'moves the stage before the last place' do
          subject

          before_last = group.cycle_analytics_stages.ordered[-2]
          expect(before_last.id).to eq(stage.id)
        end
      end
    end

    include_context 'when invalid stage parameters are given'
  end

  describe 'DELETE #destroy' do
    let(:stage) { create(:cycle_analytics_group_stage, parent: group) }

    subject { delete :destroy, params: params }

    before do
      params[:id] = stage.id
    end

    include_examples 'group permission check on the controller level'

    context 'when persisted stage id is passed' do
      it 'succeeds' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'deletes the record' do
        subject

        expect(group.reload.cycle_analytics_stages.find_by(id: stage.id)).to be_nil
      end
    end

    context 'when default stage id is passed' do
      before do
        params[:id] = Gitlab::Analytics::CycleAnalytics::DefaultStages.names.first
      end

      it 'fails with `forbidden` response' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'data endpoints' do
    let(:stage) { create(:cycle_analytics_group_stage, parent: group) }

    before do
      params[:id] = stage.id
    end

    describe 'GET #median' do
      subject { get :median, params: params }

      it 'matches the response schema' do
        subject

        expect(response).to match_response_schema('analytics/cycle_analytics/median', dir: 'ee')
      end

      include_examples 'cycle analytics data endpoint examples'
    end

    describe 'GET #records' do
      subject { get :records, params: params }

      include_examples 'cycle analytics data endpoint examples'
      include_examples 'group permission check on the controller level'
    end

    describe 'GET #duration_chart' do
      subject { get :duration_chart, params: params }

      it 'matches the response schema' do
        fake_result = [double(MergeRequest, duration_in_seconds: 10, finished_at: Time.current)]
        expect_any_instance_of(Gitlab::Analytics::CycleAnalytics::DataForDurationChart).to receive(:load).and_return(fake_result)

        subject

        expect(response).to match_response_schema('analytics/cycle_analytics/duration_chart', dir: 'ee')
      end

      include_examples 'cycle analytics data endpoint examples'
      include_examples 'group permission check on the controller level'
    end
  end
end

RSpec.shared_examples 'group permission check on the controller level' do
  context 'when `group_id` is not found' do
    before do
      params[:group_id] = 'missing_group'
    end

    it 'renders `not_found` when group is missing' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when user has no lower access level than `reporter`' do
    before do
      GroupMember.where(user: user).delete_all
      group.add_guest(user)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  context 'when feature is not available for the group' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: false)
    end

    it 'renders `forbidden` response' do
      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end
end

RSpec.shared_context 'when invalid stage parameters are given' do
  before do
    params[:name] = ''
  end

  it 'renders the validation errors' do
    subject

    expect(response).to have_gitlab_http_status(:unprocessable_entity)
    expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
  end
end

RSpec.shared_examples 'cycle analytics data endpoint examples' do
  before do
    params[:created_after] = '2019-01-01'
    params[:created_before] = '2019-04-01'
  end

  context 'when valid parameters are given' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
    end
  end

  context 'accepts optional `project_ids` array' do
    before do
      params[:project_ids] = [1, 2, 3]
    end

    it 'succeeds' do
      expect_any_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams).to receive(:project_ids=).with(%w[1 2 3]).and_call_original

      subject

      expect(response).to be_successful
    end
  end

  shared_examples 'example for invalid parameter' do
    it 'renders `unprocessable_entity`' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
      expect(response).to match_response_schema('analytics/cycle_analytics/validation_error', dir: 'ee')
    end
  end

  context 'when `created_before` is missing' do
    before do
      params.delete(:created_before)
    end

    it 'succeeds' do
      travel_to '2019-04-01' do
        subject

        expect(response).to be_successful
      end
    end
  end

  context 'when `created_after` is missing' do
    before do
      params.delete(:created_after)
    end

    it 'succeeds' do
      subject

      expect(response).to be_successful
    end
  end

  context 'when `created_after` is invalid, falls back to default date' do
    before do
      params[:created_after] = 'not-a-date'
    end

    it { expect(subject).to have_gitlab_http_status(:success) }
  end

  context 'when `created_before` is invalid' do
    before do
      params[:created_before] = 'not-a-date'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when `created_after` is later than `created_before`' do
    before do
      params[:created_after] = '2012-01-01'
      params[:created_before] = '2010-01-01'
    end

    include_examples 'example for invalid parameter'
  end

  context 'when the date range exceeds 180 days' do
    before do
      params[:created_after] = '2019-01-01'
      params[:created_before] = '2019-08-01'
    end

    include_examples 'example for invalid parameter'
  end
end
