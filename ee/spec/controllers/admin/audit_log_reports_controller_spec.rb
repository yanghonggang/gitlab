# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AuditLogReportsController do
  describe 'GET index' do
    let(:csv_data) do
      <<~CSV
        ID,Author Name,Action,Entity Type,Target Details
        18,タンさん,Added new project,Project,gitlab-org/awesome-rails
        19,\"Ru'by McRüb\"\"Face\",!@#$%^&*()`~ new project,Project,¯\\_(ツ)_/¯
        20,sǝʇʎq ƃuᴉpoɔǝp,",./;'[]\-= old project",Project,¯\\_(ツ)_/¯
      CSV
    end

    let(:params) do
      {
        entity_type: 'Project',
        entity_id: '789',
        created_before: '2020-09-01',
        created_after: '2020-08-01',
        author_id: '67'
      }
    end

    let(:export_csv_service) { instance_spy(AuditEvents::ExportCsvService, csv_data: csv_data) }

    subject { get :index, params: params, as: :csv }

    context 'when user has access' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
      end

      context 'when licensed and feature flag is enabled' do
        before do
          stub_feature_flags(audit_log_export_csv: true)
          stub_licensed_features(admin_audit_log: true)

          allow(AuditEvents::ExportCsvService).to receive(:new).and_return(export_csv_service)
        end

        it 'invokes CSV export service with correct arguments' do
          subject

          expect(AuditEvents::ExportCsvService).to have_received(:new)
            .with(ActionController::Parameters.new(params).permit!)
        end

        it 'returns success status with correct headers', :aggregate_failures do
          freeze_time do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers["Content-Length"]).to be_nil
            expect(response.headers["Cache-Control"]).to eq('no-cache, no-store')
            expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8; header=present')
            expect(response.headers['X-Accel-Buffering']).to eq('no')
            expect(response.headers['Last-Modified']).to eq('0')
            expect(response.headers['Content-Disposition'])
              .to include("filename=\"audit-events-#{Time.current.to_i}.csv\"")
          end
        end

        it 'returns a csv file in response', :aggregate_failures do
          subject

          expect(csv_response).to eq([
            ["ID", "Author Name", "Action", "Entity Type", "Target Details"],
            ["18", "タンさん", "Added new project", "Project", "gitlab-org/awesome-rails"],
            ["19", "Ru'by McRüb\"Face", "!@#$%^&*()`~ new project", "Project", "¯\\_(ツ)_/¯"],
            ["20", "sǝʇʎq ƃuᴉpoɔǝp", ",./;'[]\-= old project", "Project", "¯\\_(ツ)_/¯"]
          ])
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(audit_log_export_csv: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end

      context 'when unlicensed' do
        before do
          stub_licensed_features(admin_audit_log: false)
        end

        it { is_expected.to have_gitlab_http_status(:not_found) }
      end
    end

    context 'when user does not have access' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end
end
