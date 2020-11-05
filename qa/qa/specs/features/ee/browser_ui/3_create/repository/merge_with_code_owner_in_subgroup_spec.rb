# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Codeowners' do
      context 'when the project is in a subgroup', :requires_admin do
        let(:approver) do
          Resource::User.fabricate_via_api! do |resource|
            resource.api_client = Runtime::API::Client.as_admin
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = "approve-and-merge"
            project.initialize_with_readme = true
          end
        end

        before do
          group_or_project.add_member(approver, Resource::Members::AccessLevel::MAINTAINER)

          Flow::Login.sign_in

          project.visit!
        end

        after do
          group_or_project.remove_member(approver)
          approver.remove_via_api!
        end

        context 'and the code owner is the root group' do
          let(:codeowner) { project.group.sandbox.path }
          let(:group_or_project) { project.group.sandbox }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is the subgroup' do
          let(:codeowner) { project.group.full_path }
          let(:group_or_project) { project.group }

          it_behaves_like 'code owner merge request'
        end

        context 'and the code owner is a user' do
          let(:codeowner) { approver.username }
          let(:group_or_project) { project }

          it_behaves_like 'code owner merge request'
        end
      end
    end
  end
end
