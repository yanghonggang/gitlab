# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Restricted protected branch push and merge' do
      let(:user_developer) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1) }
      let(:user_maintainer) { Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2) }
      let(:branch_name) { 'protected-branch' }
      let(:commit_message) { 'Protected push commit message' }

      shared_examples 'only user with access pushes and merges' do
        it 'unselected maintainer user fails to push' do
          expect { push_new_file(branch_name, as_user: user_maintainer) }.to raise_error(
            QA::Support::Run::CommandError,
            /remote: GitLab: You are not allowed to push code to protected branches on this project\.([\s\S]+)\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end

        it 'selected developer user pushes and merges' do
          push = push_new_file(branch_name, as_user: user_developer)

          expect(push.output).to match(/remote: To create a merge request for protected-branch, visit/)

          Resource::MergeRequest.fabricate_via_api! do |merge_request|
            merge_request.project = project
            merge_request.target_new_branch = false
            merge_request.source_branch = branch_name
            merge_request.no_preparation = true
          end.visit!

          Page::MergeRequest::Show.perform(&:merge!)

          expect(page).to have_content('The changes were merged')
        end
      end

      context 'when only one user is allowed to merge and push to a protected branch' do
        let(:project) do
          Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'user-with-access-to-protected-branch'
            resource.initialize_with_readme = true
          end
        end

        before do
          project.add_member(user_developer, Resource::Members::AccessLevel::DEVELOPER)
          project.add_member(user_maintainer, Resource::Members::AccessLevel::MAINTAINER)

          login

          Resource::ProtectedBranch.fabricate! do |protected_branch|
            protected_branch.branch_name = branch_name
            protected_branch.project = project
            protected_branch.allowed_to_merge = {
              users: [user_developer]
            }
            protected_branch.allowed_to_push = {
              users: [user_developer]
            }
          end
        end

        it_behaves_like 'only user with access pushes and merges'
      end

      context 'when only one group is allowed to merge and push to a protected branch' do
        let(:group) do
          Resource::Group.fabricate_via_api! do |group|
            group.path = "access-to-protected-branch-#{SecureRandom.hex(8)}"
          end
        end

        let(:project) do
          Resource::Project.fabricate_via_api! do |resource|
            resource.name = 'group-with-access-to-protected-branch'
            resource.initialize_with_readme = true
          end
        end

        before do
          login

          group.add_member(user_developer, Resource::Members::AccessLevel::DEVELOPER)
          project.share_with_group(group, Resource::Members::AccessLevel::DEVELOPER)

          project.add_member(user_maintainer, Resource::Members::AccessLevel::MAINTAINER)

          Resource::ProtectedBranch.fabricate! do |protected_branch|
            protected_branch.branch_name = branch_name
            protected_branch.project = project
            protected_branch.allowed_to_merge = {
              groups: [group]
            }
            protected_branch.allowed_to_push = {
              groups: [group]
            }
          end
        end

        it_behaves_like 'only user with access pushes and merges'
      end

      def login(as_user: Runtime::User)
        Page::Main::Menu.perform(&:sign_out_if_signed_in)

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform do |login|
          login.sign_in_using_credentials(user: as_user)
        end
      end

      def push_new_file(branch, as_user: user)
        Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = project.repository_http_location.uri
          push.branch_name = branch_name
          push.new_branch = false
          push.user = as_user
        end
      end
    end
  end
end
