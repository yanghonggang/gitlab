# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'authorize read pipeline' do
  context 'public project with private builds' do
    let(:comparison_status) { {} }
    let(:project) { create(:project, :public, :builds_private) }

    it 'restricts access to signed out users' do
      sign_out user

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'restricts access to other users' do
      sign_in create(:user)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end

RSpec.shared_examples 'pending pipeline response' do
  context 'when pipeline is pending' do
    let(:comparison_status) { nil }

    before do
      merge_request.head_pipeline.run!
    end

    it 'sends polling interval' do
      expect(::Gitlab::PollingInterval).to receive(:set_header)

      subject
    end

    it 'returns 204 HTTP status' do
      subject

      expect(response).to have_gitlab_http_status(:no_content)
    end
  end
end

RSpec.describe Projects::MergeRequestsController do
  include ProjectForksHelper

  let(:project)       { create(:project, :repository) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: create(:user)) }
  let(:user)          { project.creator }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  describe 'GET index' do
    def get_merge_requests
      get :index,
        params: {
          namespace_id: project.namespace.to_param,
          project_id: project,
          state: 'opened'
        }
    end

    context 'when filtering by opened state' do
      context 'with opened merge requests' do
        render_views
        it 'avoids N+1' do
          other_user = create(:user)
          create(:merge_request, :unique_branches, target_project: project, source_project: project)
          create_list(:approval_merge_request_rule, 5, merge_request: merge_request, users: [user, other_user], approvals_required: 2)

          control_count = ActiveRecord::QueryRecorder.new { get_merge_requests }.count

          create_list(:approval, 10)
          create_list(:merge_request, 20, :unique_branches, target_project: project, source_project: project).each do |mr|
            create(:approval_merge_request_rule, merge_request: merge_request, users: [user, other_user], approvals_required: 2)
          end

          expect do
            get_merge_requests
          end.not_to exceed_query_limit(control_count)
        end
      end
    end
  end

  describe 'PUT update' do
    before do
      project.update(approvals_before_merge: 2)
    end

    def update_merge_request(params = {})
      post :update,
        params: {
          namespace_id: merge_request.target_project.namespace.to_param,
          project_id: merge_request.target_project.to_param,
          id: merge_request.iid,
          merge_request: params
        }
    end

    context 'when the merge request requires approval' do
      before do
        project.update!(approvals_before_merge: 1)
      end

      it_behaves_like 'update invalid issuable', MergeRequest
    end

    context 'overriding approvers per MR' do
      before do
        project.update!(approvals_before_merge: 1)
      end

      context 'enabled' do
        before do
          project.update!(disable_overriding_approvers_per_merge_request: false)
        end

        it 'updates approvals' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(2)
        end

        it 'does not allow approvels before merge lower than the project setting' do
          update_merge_request(approvals_before_merge: 0)

          expect(merge_request.reload.approvals_before_merge).to eq(1)
        end

        it 'creates rules' do
          users = create_list(:user, 3)
          users.each { |user| project.add_developer(user) }

          update_merge_request(approval_rules_attributes: [
            { name: 'foo', user_ids: users.map(&:id), approvals_required: 3 }
          ])

          expect(merge_request.reload.approval_rules.size).to eq(1)

          rule = merge_request.reload.approval_rules.first

          expect(rule.name).to eq('foo')
          expect(rule.approvals_required).to eq(3)
        end
      end

      context 'disabled' do
        let(:new_approver) { create(:user) }
        let(:new_approver_group) { create(:approver_group) }

        before do
          project.add_developer(new_approver)
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it 'does not update approvals_before_merge' do
          update_merge_request(approvals_before_merge: 2)

          expect(merge_request.reload.approvals_before_merge).to eq(nil)
        end

        it 'does not update approver_ids' do
          update_merge_request(approver_ids: [new_approver].map(&:id).join(','))

          expect(merge_request.reload.approver_ids).to be_empty
        end

        it 'does not update approver_group_ids' do
          update_merge_request(approver_group_ids: [new_approver_group].map(&:id).join(','))

          expect(merge_request.reload.approver_group_ids).to be_empty
        end

        it 'does not create approval rules' do
          update_merge_request(
            approval_rules_attributes: [
              {
                name: 'Test',
                user_ids: [new_approver.id],
                approvals_required: 1
              }
            ]
          )

          expect(merge_request.reload.approval_rules).to be_empty
        end
      end
    end

    shared_examples 'approvals_before_merge param' do
      before do
        project.update(approvals_before_merge: 2)
      end

      context 'approvals_before_merge not set for the existing MR' do
        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the sames as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end

      context 'approvals_before_merge set for the existing MR' do
        before do
          merge_request.update_attribute(:approvals_before_merge, 4)
        end

        context 'when it is not set' do
          before do
            update_merge_request(title: 'New title')
          end

          it 'does not change the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(4)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is less than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 1)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is equal to the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 2)
          end

          it 'sets the param to the same as the target project' do
            expect(merge_request.reload.approvals_before_merge).to eq(2)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end

        context 'when it is greater than the one in the target project' do
          before do
            update_merge_request(approvals_before_merge: 3)
          end

          it 'saves the param in the merge request' do
            expect(merge_request.reload.approvals_before_merge).to eq(3)
          end

          it 'updates the merge request' do
            expect(merge_request.reload).to be_valid
            expect(response).to redirect_to(project_merge_request_path(merge_request.target_project, merge_request))
          end
        end
      end
    end

    context 'when the MR targets the project' do
      it_behaves_like 'approvals_before_merge param'
    end

    context 'when the project is a fork' do
      let(:upstream) { create(:project, :repository) }
      let(:project) { fork_project(upstream, nil, repository: true) }

      context 'when the MR target upstream' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting upstream', source_project: project, target_project: upstream) }

        before do
          upstream.add_developer(user)
          upstream.update!(approvals_before_merge: 2)
        end

        it_behaves_like 'approvals_before_merge param'
      end

      context 'when the MR target the fork' do
        let(:merge_request) { create(:merge_request, title: 'This is targeting the fork', source_project: project, target_project: project) }

        before do
          project.add_developer(user)
          project.update(approvals_before_merge: 0)
        end

        it_behaves_like 'approvals_before_merge param'
      end
    end
  end

  describe 'POST #rebase' do
    def post_rebase
      post :rebase, params: { namespace_id: project.namespace, project_id: project, id: merge_request }
    end

    def expect_rebase_worker_for(user)
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, user.id, false)
    end

    context 'approvals pending' do
      let(:project) { create(:project, :repository, approvals_before_merge: 1) }

      it 'returns 200' do
        expect_rebase_worker_for(viewer)

        post_rebase

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET #dependency_scanning_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_dependency_scanning_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dependency_scanning_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSecurityReportsService, viewer, 'dependency_scanning').and_return(comparison_status)
    end

    it_behaves_like 'pending pipeline response'

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse container scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse container scanning reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  describe 'GET #container_scanning_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_container_scanning_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :container_scanning_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSecurityReportsService, viewer, 'container_scanning').and_return(comparison_status)
    end

    it_behaves_like 'pending pipeline response'

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse container scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse container scanning reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  describe 'GET #sast_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_sast_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :sast_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSecurityReportsService, viewer, 'sast').and_return(comparison_status)
    end

    it_behaves_like 'pending pipeline response'

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse sast reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse sast reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  describe 'GET #secret_detection_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_secret_detection_reports, source_project: project, author: create(:user)) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid

      }
    end

    subject { get :secret_detection_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSecurityReportsService, viewer, 'secret_detection').and_return(comparison_status)
    end

    it_behaves_like 'pending pipeline response'

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse secret detection reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse secret detection reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  describe 'GET #dast_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_dast_reports, source_project: project) }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :dast_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareSecurityReportsService, viewer, 'dast').and_return(comparison_status)
    end

    it_behaves_like 'pending pipeline response'

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { added: [], fixed: [], existing: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "added" => [], "fixed" => [], "existing" => [] })
      end
    end

    context 'when user created corrupted vulnerability reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse DAST reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse DAST reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  describe 'GET #license_scanning_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: project, author: create(:user)) }
    let(:comparison_status) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :license_scanning_reports, params: params, format: :json }

    before do
      stub_licensed_features(license_scanning: true)
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareLicenseScanningReportsService, viewer).and_return(comparison_status)
    end

    context 'when the pipeline is running' do
      before do
        allow(::Gitlab::PollingInterval).to receive(:set_header)
        merge_request.head_pipeline.update!(status: :running)

        subject
      end

      context 'when the report is being parsed' do
        let(:comparison_status) { { status: :parsing } }

        specify { expect(::Gitlab::PollingInterval).to have_received(:set_header) }
        specify { expect(response).to have_gitlab_http_status(:no_content) }
      end

      context 'when the report is ready' do
        let(:comparison_status) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }

        specify { expect(::Gitlab::PollingInterval).not_to have_received(:set_header) }
        specify { expect(response).to have_gitlab_http_status(:ok) }
        specify { expect(json_response).to eq({ "new_licenses" => [], "existing_licenses" => [], "removed_licenses" => [] }) }
      end
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { new_licenses: [], existing_licenses: [], removed_licenses: [] } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ "new_licenses" => [], "existing_licenses" => [], "removed_licenses" => [] })
      end
    end

    context 'when user created corrupted test reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse license scanning reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse license scanning reports' })
      end
    end

    context "when a user is NOT authorized to read licenses on a project" do
      let(:project) { create(:project, :repository, :private) }
      let(:viewer) { create(:user) }

      it 'returns a report' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context "when a user is authorized to read the licenses" do
      let(:project) { create(:project, :repository, :private) }
      let(:viewer) { create(:user) }

      before do
        project.add_reporter(viewer)
      end

      it 'returns a report' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context "when a maintainer is authorized to read licenses on a merge request from a forked project" do
      let(:project) { create(:project, :repository, :public, :builds_private) }
      let(:forked_project) { fork_project(project, nil, repository: true) }
      let(:merge_request) { create(:ee_merge_request, :with_license_scanning_reports, source_project: forked_project, target_project: project) }
      let(:viewer) { create(:user) }

      before do
        project.add_maintainer(viewer)
        forked_project.add_maintainer(user)
      end

      it 'returns a report' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET #metrics_reports' do
    let(:merge_request) { create(:ee_merge_request, :with_metrics_reports, source_project: project, author: create(:user)) }

    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: merge_request.iid
      }
    end

    subject { get :metrics_reports, params: params, format: :json }

    before do
      allow_any_instance_of(::MergeRequest).to receive(:compare_reports)
        .with(::Ci::CompareMetricsReportsService).and_return(comparison_status)
    end

    context 'when comparison is being processed' do
      let(:comparison_status) { { status: :parsing } }

      it 'sends polling interval' do
        expect(::Gitlab::PollingInterval).to receive(:set_header)

        subject
      end

      it 'returns 204 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when comparison is done' do
      let(:comparison_status) { { status: :parsed, data: { summary: 1 } } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 200 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'summary' => 1 })
      end
    end

    context 'when user created corrupted test reports' do
      let(:comparison_status) { { status: :error, status_reason: 'Failed to parse test reports' } }

      it 'does not send polling interval' do
        expect(::Gitlab::PollingInterval).not_to receive(:set_header)

        subject
      end

      it 'returns 400 HTTP status' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'status_reason' => 'Failed to parse test reports' })
      end
    end

    it_behaves_like 'authorize read pipeline'
  end

  it_behaves_like DescriptionDiffActions do
    let_it_be(:project)  { create(:project, :repository, :public) }
    let_it_be(:issuable) { create(:merge_request, source_project: project) }
  end
end
