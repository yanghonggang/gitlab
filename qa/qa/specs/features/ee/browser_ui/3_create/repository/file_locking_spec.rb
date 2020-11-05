# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'File Locking' do
      before do
        Flow::Login.sign_in

        @user_one = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
        @user_two = Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_2, Runtime::Env.gitlab_qa_password_2)

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'file_locking'
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.file_name = 'file'
          push.file_content = SecureRandom.hex(100000)
        end

        add_to_project user: @user_one
        add_to_project user: @user_two

        Resource::ProtectedBranch.unprotect_via_api! do |branch|
          branch.project = @project
          branch.branch_name = 'master'
        end
      end

      it 'locks a directory and tries to push as a second user', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/557' do
        push branch: 'master', file: 'directory/file', as_user: @user_one

        sign_out_and_sign_in_as user: @user_one
        go_to_directory
        click_lock

        expect_error_on_push for_file: 'directory/file', as_user: @user_two
        expect_no_error_on_push for_file: 'directory/file', as_user: @user_one
      end

      it 'locks a file and tries to push as a second user', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/558' do
        sign_out_and_sign_in_as user: @user_one
        go_to_file
        click_lock

        expect_error_on_push as_user: @user_two
        expect_no_error_on_push as_user: @user_one
      end

      it 'checks file locked by other user to be disabled', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/556' do
        go_to_file
        click_lock
        sign_out_and_sign_in_as user: @user_one
        go_to_file

        Page::File::Show.perform do |show|
          expect(show).to have_lock_button_disabled
        end
      end

      it 'creates a merge request and fails to merge', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/issues/40125', type: :bug }, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/559' do
        push branch: 'test', as_user: @user_one

        merge_request = Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = @project
          merge_request.source_branch = 'test'
          merge_request.target_branch = 'master'
          merge_request.no_preparation = true
        end

        go_to_file
        click_lock
        sign_out_and_sign_in_as user: @user_one
        try_to_merge merge_request: merge_request
        Page::MergeRequest::Show.perform(&:wait_for_merge_request_error_message)
        expect(page).to have_text("locked by #{admin_username}")
      end

      it 'locks a file and unlocks in list', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/555' do
        sign_out_and_sign_in_as user: @user_one
        go_to_file
        click_lock
        @project.visit!

        Page::Project::Menu.perform(&:go_to_repository_locked_files)
        EE::Page::Project::PathLocks::Index.perform do |list|
          expect(list).to have_file_with_title 'file'
          list.unlock_file 'file'
        end

        expect_no_error_on_push as_user: @user_two
      end

      def try_to_merge(merge_request:)
        merge_request.visit!
        Page::MergeRequest::Show.perform do |show|
          show.try_to_merge!
        end
      end

      def sign_out_and_sign_in_as(user:)
        Page::Main::Login.perform do |login|
          login.sign_out_and_sign_in_as user: user
        end
      end

      def go_to_file
        @project.visit!
        Page::Project::Show.perform do |project_page|
          project_page.click_file 'file'
        end
      end

      def go_to_directory
        @project.visit!
        Page::Project::Show.perform do |project_page|
          project_page.click_file 'directory'
        end
      end

      def click_lock
        Page::File::Show.perform(&:lock)
      end

      def add_to_project(user:)
        Resource::ProjectMember.fabricate_via_api! do |member|
          member.user = user
          member.project = @project
          member.access_level = member.level[:developer]
        end
      end

      def push(branch: 'master', file: 'file', as_user:)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.new_branch = false unless branch != 'master'
          push.file_name = file
          push.file_content = SecureRandom.hex(100000)
          push.user = as_user
          push.branch_name = branch
        end
      end

      def expect_error_on_push(for_file: 'file', as_user:)
        expect { push branch: 'master', file: for_file, as_user: as_user }.to raise_error(
          QA::Support::Run::CommandError)
      end

      def expect_no_error_on_push(for_file: 'file', as_user:)
        expect { push branch: 'master', file: for_file, as_user: as_user }.not_to raise_error
      end

      def admin_username
        Resource::User.fabricate_via_api! do |user|
          user.username = Runtime::User.username
        end.name
      end
    end
  end
end
