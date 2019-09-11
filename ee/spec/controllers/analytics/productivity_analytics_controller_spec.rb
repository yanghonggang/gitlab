# frozen_string_literal: true

require 'spec_helper'

describe Analytics::ProductivityAnalyticsController do
  let(:current_user) { create(:user) }

  before do
    sign_in(current_user) if current_user

    stub_licensed_features(productivity_analytics: true)
  end

  describe 'GET show' do
    subject { get :show }

    it 'checks for premium license' do
      stub_licensed_features(productivity_analytics: false)

      subject

      expect(response.code).to eq '404'
    end

    it 'authorizes for ability to view analytics' do
      expect(Ability).to receive(:allowed?).with(current_user, :view_productivity_analytics, :global).and_return(false)

      subject

      expect(response.code).to eq '403'
    end

    it 'renders show template' do
      subject

      expect(response).to render_template :show
    end
  end

  describe 'GET show.json' do
    subject { get :show, format: :json, params: params }
    let(:params) { {} }

    let(:analytics_mock) { instance_double('ProductivityAnalytics') }

    before do
      merge_requests = double
      allow_any_instance_of(ProductivityAnalyticsFinder).to receive(:execute).and_return(merge_requests)
      allow(ProductivityAnalytics)
        .to receive(:new)
              .with(merge_requests: merge_requests, sort: params[:sort])
              .and_return(analytics_mock)
    end

    context 'with non-existing group_id' do
      let(:params) { { group_id: 'SOMETHING_THAT_DOES_NOT_EXIST' } }

      it 'renders 404' do
        subject
        expect(response.code).to eq '404'
      end
    end

    context 'with non-existing project_id' do
      let(:group) { create :group }
      let(:params) { { group_id: group.full_path, project_id: 'SOMETHING_THAT_DOES_NOT_EXIST' } }

      it 'renders 404' do
        subject
        expect(response.code).to eq '404'
      end
    end

    context 'for list of MRs' do
      let!(:merge_request ) { create :merge_request, :merged}

      let(:serializer_mock) { instance_double('BaseSerializer') }

      before do
        allow(BaseSerializer).to receive(:new).with(current_user: current_user).and_return(serializer_mock)
        allow(analytics_mock).to receive(:merge_requests_extended).and_return(MergeRequest.all)
        allow(serializer_mock).to receive(:represent)
                                    .with(merge_request, {}, ProductivityAnalyticsMergeRequestEntity)
                                    .and_return('mr_representation')
      end

      it 'serializes whatever analytics returns with ProductivityAnalyticsMergeRequestEntity' do
        subject

        expect(response.body).to eq '["mr_representation"]'
      end

      it 'sets pagination headers' do
        subject

        expect(response.headers['X-Per-Page']).to eq '20'
        expect(response.headers['X-Page']).to eq '1'
        expect(response.headers['X-Next-Page']).to eq ''
        expect(response.headers['X-Prev-Page']).to eq ''
        expect(response.headers['X-Total']).to eq '1'
        expect(response.headers['X-Total-Pages']).to eq '1'
      end
    end

    context 'for scatterplot charts' do
      let(:params) { { chart_type: 'scatterplot', metric_type: 'commits_count' } }
      it 'renders whatever analytics returns for scatterplot' do
        allow(analytics_mock).to receive(:scatterplot_data).with(type: 'commits_count').and_return('scatterplot_data')

        subject

        expect(response.body).to eq 'scatterplot_data'
      end
    end

    context 'for histogram charts' do
      let(:params) { { chart_type: 'histogram', metric_type: 'commits_count' } }
      it 'renders whatever analytics returns for histogram' do
        allow(analytics_mock).to receive(:histogram_data).with(type: 'commits_count').and_return('histogram_data')

        subject

        expect(response.body).to eq 'histogram_data'
      end
    end
  end
end
