# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::HooksController do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with group_webhooks enabled' do
    before do
      stub_licensed_features(group_webhooks: true)
    end

    describe 'GET #index' do
      it 'is successfull' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    describe 'POST #create' do
      it 'sets all parameters' do
        hook_params = {
          job_events: true,
          confidential_issues_events: true,
          enable_ssl_verification: true,
          issues_events: true,
          merge_requests_events: true,
          note_events: true,
          pipeline_events: true,
          push_events: true,
          tag_push_events: true,
          token: 'TEST TOKEN',
          url: 'http://example.com',
          wiki_page_events: true,
          deployment_events: true
        }

        post :create, params: { group_id: group.to_param, hook: hook_params }

        expect(response).to have_gitlab_http_status(:found)
        expect(group.hooks.size).to eq(1)
        expect(group.hooks.first).to have_attributes(hook_params)
      end
    end

    describe 'GET #edit' do
      let(:hook) { create(:group_hook, group: group) }

      it 'is successfull' do
        get :edit, params: { group_id: group.to_param, id: hook }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:edit)
        expect(group.hooks.size).to eq(1)
      end
    end

    describe 'PATCH #update' do
      let(:hook) { create(:group_hook, group: group) }

      context 'valid params' do
        let(:hook_params) do
          {
            job_events: true,
            confidential_issues_events: true,
            enable_ssl_verification: true,
            issues_events: true,
            merge_requests_events: true,
            note_events: true,
            pipeline_events: true,
            push_events: true,
            tag_push_events: true,
            token: 'TEST TOKEN',
            url: 'http://example.com',
            wiki_page_events: true,
            deployment_events: true,
            releases_events: true
          }
        end

        it 'is successfull' do
          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to(group_hooks_path(group))
          expect(group.hooks.size).to eq(1)
          expect(group.hooks.first).to have_attributes(hook_params)
        end
      end

      context 'invalid params' do
        let(:hook_params) do
          {
            url: ''
          }
        end

        it 'renders "edit" template' do
          patch :update, params: { group_id: group.to_param, id: hook, hook: hook_params }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to render_template(:edit)
          expect(group.hooks.size).to eq(1)
          expect(group.hooks.first).not_to have_attributes(hook_params)
        end
      end
    end

    describe 'POST #test' do
      let(:hook) { create(:group_hook, group: group) }

      context 'when group does not have a project' do
        it 'redirects back' do
          expect(TestHooks::ProjectService).not_to receive(:new)

          post :test, params: { group_id: group.to_param, id: hook }

          expect(response).to have_gitlab_http_status(:found)
          expect(flash[:alert]).to eq('Hook execution failed. Ensure the group has a project with commits.')
        end
      end

      context 'when group has a project' do
        let!(:project) { create(:project, :repository, group: group) }

        context 'when "trigger" params is empty' do
          it 'defaults to "push_events"' do
            expect_next_instance_of(TestHooks::ProjectService, hook, user, 'push_events') do |service|
              expect(service).to receive(:execute).and_return(http_status: 200)
            end

            post :test, params: { group_id: group.to_param, id: hook }

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to eq('Hook executed successfully: HTTP 200')
          end
        end

        context 'when "trigger" params is set' do
          let(:trigger) { 'issue_hooks' }

          it 'uses it' do
            expect_next_instance_of(TestHooks::ProjectService, hook, user, trigger) do |service|
              expect(service).to receive(:execute).and_return(http_status: 200)
            end

            post :test, params: { group_id: group.to_param, id: hook, trigger: trigger }

            expect(response).to have_gitlab_http_status(:found)
            expect(flash[:notice]).to eq('Hook executed successfully: HTTP 200')
          end
        end

        context 'when the endpoint receives requests above the limit' do
          before do
            allow(Gitlab::ApplicationRateLimiter).to receive(:rate_limits)
              .and_return(group_testing_hook: { threshold: 1, interval: 1.minute })
          end

          it 'prevents making test requests' do
            expect_next_instance_of(TestHooks::ProjectService) do |service|
              expect(service).to receive(:execute).and_return(http_status: 200)
            end

            2.times { post :test, params: { group_id: group.to_param, id: hook } }

            expect(response.body).to eq(_('This endpoint has been requested too many times. Try again later.'))
            expect(response).to have_gitlab_http_status(:too_many_requests)
          end
        end
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:hook) { create(:group_hook, group: group) }
    let!(:log) { create(:web_hook_log, web_hook: hook) }
    let(:params) { { group_id: group.to_param, id: hook } }

    it_behaves_like 'Web hook destroyer'
  end

  context 'with group_webhooks disabled' do
    before do
      stub_licensed_features(group_webhooks: false)
    end

    describe 'GET #index' do
      it 'renders a 404' do
        get :index, params: { group_id: group.to_param }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
