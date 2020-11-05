# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectApprovalRules do
  let_it_be(:group) { create(:group_with_members) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let_it_be(:approver) { create(:user) }
  let_it_be(:other_approver) { create(:user) }

  describe 'GET /projects/:id/approval_rules' do
    let(:url) { "/projects/#{project.id}/approval_rules" }

    context 'when the request is correct' do
      let!(:rule) do
        rule = create(:approval_project_rule, name: 'vulnerability', project: project, approvals_required: 7)
        rule.users << approver
        rule
      end

      let(:developer) do
        user = create(:user)
        project.add_guest(user)
        user
      end

      it 'matches the response schema' do
        get api(url, developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/project_approval_rules', dir: 'ee')

        json = json_response

        expect(json.size).to eq(1)

        rule = json.first

        expect(rule['approvals_required']).to eq(7)
        expect(rule['name']).to eq('vulnerability')
      end

      context 'private group filtering' do
        let_it_be(:private_group) { create :group, :private }

        before do
          rule.groups << private_group
        end

        it 'excludes private groups if user has no access' do
          get api(url, developer)

          json = json_response
          rule = json.first

          expect(rule['groups'].size).to eq(0)
        end

        it 'includes private groups if user has access' do
          private_group.add_owner(developer)

          get api(url, developer)

          json = json_response
          rule = json.first

          expect(rule['groups'].size).to eq(1)
        end
      end

      context 'report_approver rules' do
        let!(:report_approver_rule) do
          create(:approval_project_rule, :vulnerability_report, project: project)
        end

        it 'includes report_approver rules' do
          get api(url, developer)

          json = json_response

          expect(json.size).to eq(2)
          expect(json.map { |rule| rule['name'] }).to contain_exactly(rule.name, report_approver_rule.name)
        end
      end
    end
  end

  describe 'POST /projects/:id/approval_rules' do
    let(:schema) { 'public_api/v4/project_approval_rule' }
    let(:url) { "/projects/#{project.id}/approval_rules" }

    it_behaves_like 'an API endpoint for creating project approval rule'
  end

  describe 'PUT /projects/:id/approval_rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:schema) { 'public_api/v4/project_approval_rule' }
    let(:url) { "/projects/#{project.id}/approval_rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for updating project approval rule'
  end

  describe 'DELETE /projects/:id/approval_rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:url) { "/projects/#{project.id}/approval_rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for deleting project approval rule'
  end
end
