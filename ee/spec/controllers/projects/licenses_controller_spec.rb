# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LicensesController do
  describe "GET #index" do
    let_it_be(:project) { create(:project, :repository, :private) }
    let_it_be(:user) { create(:user) }
    let(:params) { { namespace_id: project.namespace, project_id: project } }
    let(:get_licenses) { get :index, params: params, format: :json }

    before do
      sign_in(user)
    end

    context 'with authorized user' do
      context 'when feature is available' do
        before do
          stub_licensed_features(license_scanning: true)
        end

        context 'with reporter' do
          before do
            project.add_reporter(user)
          end

          context "when requesting HTML" do
            subject { get :index, params: params }

            let_it_be(:mit_license) { create(:software_license, :mit) }
            let_it_be(:apache_license) { create(:software_license, :apache_2_0) }
            let_it_be(:custom_license) { create(:software_license, :user_entered) }

            before do
              subject
            end

            it 'returns the necessary licenses app data' do
              licenses_app_data = assigns(:licenses_app_data)

              expect(response).to have_gitlab_http_status(:ok)
              expect(licenses_app_data[:project_licenses_endpoint]).to eql(controller.helpers.project_licenses_path(project, detected: true, format: :json))
              expect(licenses_app_data[:read_license_policies_endpoint]).to eql(controller.helpers.api_v4_projects_managed_licenses_path(id: project.id))
              expect(licenses_app_data[:write_license_policies_endpoint]).to eql('')
              expect(licenses_app_data[:documentation_path]).to eql(help_page_path('user/compliance/license_compliance/index'))
              expect(licenses_app_data[:empty_state_svg_path]).to eql(controller.helpers.image_path('illustrations/Dependency-list-empty-state.svg'))
              expect(licenses_app_data[:software_licenses]).to eql([apache_license.name, mit_license.name])
              expect(licenses_app_data[:project_id]).to eql(project.id)
              expect(licenses_app_data[:project_path]).to eql(controller.helpers.api_v4_projects_path(id: project.id))
              expect(licenses_app_data[:rules_path]).to eql(controller.helpers.api_v4_projects_approval_settings_rules_path(id: project.id))
              expect(licenses_app_data[:settings_path]).to eql(controller.helpers.api_v4_projects_approval_settings_path(id: project.id))
              expect(licenses_app_data[:approvals_documentation_path]).to eql(help_page_path('user/application_security/index', anchor: 'enabling-license-approvals-within-a-project'))
              expect(licenses_app_data[:locked_approvals_rule_name]).to eql(ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT)
            end
          end

          it 'counts usage of the feature' do
            expect(::Gitlab::UsageDataCounters::LicensesList).to receive(:count).with(:views)

            get_licenses
          end

          context 'with existing report' do
            let!(:pipeline) { create(:ci_pipeline, project: project, builds: [create(:ee_ci_build, :success, :license_scan_v2_1)]) }

            before do
              get_licenses
            end

            it 'returns success code' do
              expect(response).to have_gitlab_http_status(:ok)
            end

            it 'returns a hash with licenses' do
              expect(json_response['licenses'].length).to eq(3)
              expect(json_response['licenses'][0]).to include({
                'id' => nil,
                'classification' => 'unclassified',
                'name' => "BSD 3-Clause \"New\" or \"Revised\" License",
                'spdx_identifier' => "BSD-3-Clause",
                'url' => "https://opensource.org/licenses/BSD-3-Clause",
                'components' => [
                  {
                    "name" => "b",
                    "package_manager" => "yarn",
                    "version" => "0.1.0",
                    "blob_path" => project_blob_path(project, "#{project.default_branch}/yarn.lock")
                  },
                  {
                    "name" => "c",
                    "package_manager" => "bundler",
                    "version" => "1.1.0",
                    "blob_path" => project_blob_path(project, "#{project.default_branch}/Gemfile.lock")
                  }
                ]
              })
            end

            it 'returns status ok' do
              expect(json_response['report']['status']).to eq('ok')
            end

            it 'includes the pagination headers' do
              expect(response).to include_pagination_headers
            end

            context 'with pagination params' do
              let(:params) { { namespace_id: project.namespace, project_id: project, per_page: 2, page: 2 } }

              it 'return only 1 license' do
                expect(json_response['licenses'].length).to eq(1)
              end
            end
          end

          context "when software policies are applied to some of the most recently detected licenses" do
            let_it_be(:mit) { create(:software_license, :mit) }
            let_it_be(:mit_policy) { create(:software_license_policy, :denied, software_license: mit, project: project) }
            let_it_be(:other_license) { create(:software_license, spdx_identifier: "Other-Id") }
            let_it_be(:other_license_policy) { create(:software_license_policy, :allowed, software_license: other_license, project: project) }
            let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, builds: [create(:ee_ci_build, :license_scan_v2_1, :success)]) }

            context "when loading all policies" do
              before do
                get :index, params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  detected: false
                }, format: :json
              end

              it { expect(response).to have_gitlab_http_status(:ok) }
              it { expect(json_response["licenses"].count).to be(4) }

              it 'sorts by name by default' do
                names = json_response['licenses'].map { |x| x['name'] }

                expect(names).to eql(['BSD 3-Clause "New" or "Revised" License', 'MIT', other_license.name, 'unknown'])
              end

              it 'includes a policy for an unclassified and known license that was detected in the scan report' do
                expect(json_response.dig("licenses", 0)).to include({
                  "id" => nil,
                  "spdx_identifier" => "BSD-3-Clause",
                  "name" => "BSD 3-Clause \"New\" or \"Revised\" License",
                  "url" => "https://opensource.org/licenses/BSD-3-Clause",
                  "classification" => "unclassified"
                })
              end

              it 'includes a policy for a denied license found in the scan report' do
                expect(json_response.dig("licenses", 1)).to include({
                  "id" => mit_policy.id,
                  "spdx_identifier" => "MIT",
                  "name" => mit.name,
                  "url" => "https://opensource.org/licenses/MIT",
                  "classification" => "denied"
                })
              end

              it 'includes a policy for an allowed license NOT found in the latest scan report' do
                expect(json_response.dig("licenses", 2)).to include({
                  "id" => other_license_policy.id,
                  "spdx_identifier" => other_license.spdx_identifier,
                  "name" => other_license.name,
                  "url" => nil,
                  "classification" => "allowed"
                })
              end

              it 'includes an entry for an unclassified and unknown license found in the scan report' do
                expect(json_response.dig("licenses", 3)).to include({
                  "id" => nil,
                  "spdx_identifier" => nil,
                  "name" => "unknown",
                  "url" => nil,
                  "classification" => "unclassified"
                })
              end
            end

            context "when loading software policies that match licenses detected in the most recent license scan report" do
              before do
                get :index, params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  detected: true
                }, format: :json
              end

              it { expect(response).to have_gitlab_http_status(:ok) }

              it 'only includes policies for licenses detected in the most recent scan report' do
                expect(json_response["licenses"].count).to be(3)
              end

              it 'includes an unclassified policy for a known license detected in the scan report' do
                expect(json_response.dig("licenses", 0)).to include({
                  "id" => nil,
                  "spdx_identifier" => "BSD-3-Clause",
                  "classification" => "unclassified"
                })
              end

              it 'includes a classified license for a known license detected in the scan report' do
                expect(json_response.dig("licenses", 1)).to include({
                  "id" => mit_policy.id,
                  "spdx_identifier" => "MIT",
                  "classification" => "denied"
                })
              end

              it 'includes an unclassified and unknown license discovered in the scan report' do
                expect(json_response.dig("licenses", 2)).to include({
                  "id" => nil,
                  "spdx_identifier" => nil,
                  "name" => "unknown",
                  "url" => nil,
                  "classification" => "unclassified"
                })
              end
            end

            context "when loading `allowed` software policies only" do
              before do
                get :index, params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  classification: ['allowed']
                }, format: :json
              end

              it { expect(response).to have_gitlab_http_status(:ok) }
              it { expect(json_response["licenses"].count).to be(1) }

              it 'includes only `allowed` policies' do
                expect(json_response.dig("licenses", 0)).to include({
                  "id" => other_license_policy.id,
                  "spdx_identifier" => "Other-Id",
                  "classification" => "allowed"
                })
              end
            end

            context "when loading `allowed` and `denied` software policies" do
              before do
                get :index, params: {
                  namespace_id: project.namespace,
                  project_id: project,
                  classification: %w[allowed denied]
                }, format: :json
              end

              it { expect(response).to have_gitlab_http_status(:ok) }
              it { expect(json_response["licenses"].count).to be(2) }

              it 'includes `denied` policies' do
                expect(json_response.dig("licenses", 0)).to include({
                  "id" => mit_policy.id,
                  "spdx_identifier" => mit.spdx_identifier,
                  "classification" => mit_policy.classification
                })
              end

              it 'includes `allowed` policies' do
                expect(json_response.dig("licenses", 1)).to include({
                  "id" => other_license_policy.id,
                  "spdx_identifier" => other_license_policy.spdx_identifier,
                  "classification" => other_license_policy.classification
                })
              end
            end

            context "when loading policies ordered by `classification` in `ascending` order" do
              before do
                get :index, params: { namespace_id: project.namespace, project_id: project, sort_by: :classification, sort_direction: :asc }, format: :json
              end

              specify { expect(response).to have_gitlab_http_status(:ok) }
              specify { expect(json_response['licenses'].map { |x| x['classification'] }).to eq(%w[allowed unclassified unclassified denied]) }
            end

            context "when loading policies ordered by `classification` in `descending` order" do
              before do
                get :index, params: { namespace_id: project.namespace, project_id: project, sort_by: :classification, sort_direction: :desc }, format: :json
              end

              specify { expect(response).to have_gitlab_http_status(:ok) }
              specify { expect(json_response['licenses'].map { |x| x['classification'] }).to eq(%w[denied unclassified unclassified allowed]) }
            end
          end

          context 'without existing report' do
            let!(:pipeline) { create(:ee_ci_pipeline, :with_dependency_list_report, project: project) }

            before do
              get_licenses
            end

            it 'returns status job_not_set_up' do
              expect(json_response['report']['status']).to eq('job_not_set_up')
            end
          end
        end

        context 'with maintainer' do
          before do
            project.add_maintainer(user)
          end

          it 'responds to an HTML request' do
            get :index, params: params

            expect(response).to have_gitlab_http_status(:ok)
            licenses_app_data = assigns(:licenses_app_data)
            expect(licenses_app_data[:project_licenses_endpoint]).to eql(controller.helpers.project_licenses_path(project, detected: true, format: :json))
            expect(licenses_app_data[:read_license_policies_endpoint]).to eql(controller.helpers.api_v4_projects_managed_licenses_path(id: project.id))
            expect(licenses_app_data[:write_license_policies_endpoint]).to eql(controller.helpers.api_v4_projects_managed_licenses_path(id: project.id))
            expect(licenses_app_data[:documentation_path]).to eql(help_page_path('user/compliance/license_compliance/index'))
            expect(licenses_app_data[:empty_state_svg_path]).to eql(controller.helpers.image_path('illustrations/Dependency-list-empty-state.svg'))
          end
        end
      end

      context 'when feature is not available' do
        before do
          get_licenses
        end

        it 'returns 404' do
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with unauthorized user' do
      before do
        stub_licensed_features(license_scanning: true)

        get_licenses
      end

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:project) { create(:project, :repository, :private) }
    let(:mit_license) { create(:software_license, :mit) }
    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        software_license_policy: {
          software_license_id: mit_license.id,
          classification: 'allowed'
        }
      }
    end

    context "when authenticated" do
      let(:current_user) { create(:user) }

      before do
        stub_licensed_features(license_scanning: true)
        sign_in(current_user)
      end

      context "when the current user is not a member of the project" do
        before do
          post :create, xhr: true, params: default_params
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context "when the current user is a member of the project but not authorized to create policies" do
        before do
          project.add_guest(current_user)

          post :create, xhr: true, params: default_params
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context "when authorized as a maintainer" do
        let(:json) { json_response.with_indifferent_access }

        before do
          project.add_maintainer(current_user)
        end

        context "when creating a policy for a software license by the software license database id" do
          before do
            post :create, xhr: true, params: default_params.merge({
              software_license_policy: {
                software_license_id: mit_license.id,
                classification: 'denied'
              }
            })
          end

          it { expect(response).to have_gitlab_http_status(:created) }

          it 'creates a new policy' do
            expect(project.reload.software_license_policies.denied.count).to be(1)
            expect(project.reload.software_license_policies.denied.last.software_license).to eq(mit_license)
          end

          it 'returns the proper JSON response' do
            expect(json[:id]).to be_present
            expect(json[:spdx_identifier]).to eq(mit_license.spdx_identifier)
            expect(json[:classification]).to eq('denied')
            expect(json[:name]).to eq(mit_license.name)
            expect(json[:url]).to be_nil
            expect(json[:components]).to be_empty
          end
        end

        context "when creating a policy for a software license by the software license SPDX identifier" do
          before do
            post :create, xhr: true, params: default_params.merge({
              software_license_policy: {
                spdx_identifier: mit_license.spdx_identifier,
                classification: 'allowed'
              }
            })
          end

          it { expect(response).to have_gitlab_http_status(:created) }

          it 'creates a new policy' do
            expect(project.reload.software_license_policies.allowed.count).to be(1)
            expect(project.reload.software_license_policies.allowed.last.software_license).to eq(mit_license)
          end

          it 'returns the proper JSON response' do
            expect(json[:id]).to be_present
            expect(json[:spdx_identifier]).to eq(mit_license.spdx_identifier)
            expect(json[:classification]).to eq('allowed')
            expect(json[:name]).to eq(mit_license.name)
            expect(json[:url]).to be_nil
            expect(json[:components]).to be_empty
          end
        end

        context "when the parameters are invalid" do
          before do
            post :create, xhr: true, params: default_params.merge({
              software_license_policy: {
                spdx_identifier: nil,
                classification: 'allowed'
              }
            })
          end

          it { expect(response).to have_gitlab_http_status(:unprocessable_entity) }
          it { expect(json).to eq({ 'errors' => { "software_license" => ["can't be blank"] } }) }
        end
      end
    end
  end

  describe "PATCH #update" do
    let(:project) { create(:project, :repository, :private) }
    let(:software_license_policy) { create(:software_license_policy, project: project, software_license: mit_license) }
    let(:mit_license) { create(:software_license, :mit) }

    let(:default_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: software_license_policy.id,
        software_license_policy: { classification: "allowed" }
      }
    end

    context "when authenticated" do
      let(:current_user) { create(:user) }

      before do
        stub_licensed_features(license_scanning: true)
        sign_in(current_user)
      end

      context "when the current user is not a member of the project" do
        before do
          patch :update, xhr: true, params: default_params
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context "when the current user is a member of the project but not authorized to update policies" do
        before do
          project.add_guest(current_user)

          patch :update, xhr: true, params: default_params
        end

        it { expect(response).to have_gitlab_http_status(:not_found) }
      end

      context "when authorized as a maintainer" do
        let(:json) { json_response.with_indifferent_access }

        before do
          project.add_maintainer(current_user)
        end

        context "when updating a software license policy" do
          before do
            patch :update, xhr: true, params: default_params.merge({
              software_license_policy: {
                classification: "denied"
              }
            })
          end

          it { expect(response).to have_gitlab_http_status(:ok) }
          it { expect(software_license_policy.reload).to be_denied }

          it "generates the proper JSON response" do
            expect(json[:id]).to eql(software_license_policy.id)
            expect(json[:spdx_identifier]).to eq(mit_license.spdx_identifier)
            expect(json[:classification]).to eq("denied")
            expect(json[:name]).to eq(mit_license.name)
          end
        end

        context "when the parameters are invalid" do
          before do
            patch :update, xhr: true, params: default_params.merge({
              software_license_policy: {
                classification: "invalid"
              }
            })
          end

          it { expect(response).to have_gitlab_http_status(:unprocessable_entity) }
          it { expect(json).to eq({ "errors" => { "classification" => ["is invalid"] } }) }
        end
      end
    end

    context "when unauthenticated" do
      before do
        patch :update, xhr: true, params: default_params
      end

      it { expect(response).to redirect_to(new_user_session_path) }
    end
  end
end
