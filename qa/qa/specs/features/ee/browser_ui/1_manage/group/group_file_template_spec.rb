# frozen_string_literal: true

require 'securerandom'

module QA
  RSpec.describe 'Manage' do
    describe 'Group file templates', :requires_admin do
      include Support::Api

      templates = [
        {
          file_name: 'Dockerfile',
          template: 'custom_dockerfile',
          file_path: 'Dockerfile/custom_dockerfile.dockerfile',
          content: 'dockerfile template test'
        },
        {
          file_name: '.gitignore',
          template: 'custom_gitignore',
          file_path: 'gitignore/custom_gitignore.gitignore',
          content: 'gitignore template test'
        },
        {
          file_name: '.gitlab-ci.yml',
          template: 'custom_gitlab-ci',
          file_path: 'gitlab-ci/custom_gitlab-ci.yml',
          content:
            <<~CI
              job:
                script: echo "Skipped"
                except:
                  - master
            CI
        },
        {
          file_name: 'LICENSE',
          template: 'custom_license',
          file_path: 'LICENSE/custom_license.txt',
          content: 'license template test'
        }
      ]

      before(:all) do
        admin = QA::Resource::User.new.tap do |user|
          user.username = QA::Runtime::User.admin_username
          user.password = QA::Runtime::User.admin_password
        end
        @api_client = Runtime::API::Client.new(:gitlab, user: admin)
        @api_client.personal_access_token

        @group = Resource::Group.fabricate_via_api! do |group|
          group.path = 'template-group'
          group.api_client = @api_client
        end

        Support::Retrier.retry_until(retry_on_exception: true) do
          @file_template_project = Resource::Project.fabricate_via_api! do |project|
            project.group = @group
            project.name = 'group-file-template-project'
            project.description = 'Add group file templates'
            project.auto_devops_enabled = false
            project.initialize_with_readme = true
            project.api_client = @api_client
          end

          @file_template_project.has_file?("README.md")
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = @file_template_project
          commit.commit_message = 'Add group file templates'
          commit.add_files(templates)
          commit.api_client = @api_client
        end

        @project = Resource::Project.fabricate_via_api! do |project|
          project.group = @group
          project.name = 'group-file-template-project-2'
          project.description = 'Add files for group file templates'
          project.auto_devops_enabled = false
          project.initialize_with_readme = true
          project.api_client = @api_client
        end
      end

      after(:all) do
        Flow::Login.while_signed_in_as_admin do
          remove_group_file_template_if_set
        end
      end

      templates.each do |template|
        it "creates file via custom #{template[:file_name]} file template" do
          Flow::Login.sign_in_as_admin

          set_file_template_if_not_already_set

          @project.visit!

          Page::Project::Show.perform(&:create_new_file!)
          Page::File::Form.perform do |form|
            Support::Retrier.retry_until do
              form.select_template template[:file_name], template[:template]

              form.has_normalized_ws_text?(template[:content])
            end

            form.add_name("#{SecureRandom.hex(8)}/#{template[:file_name]}")
            form.commit_changes
            form.finished_loading?

            aggregate_failures "indications of file created" do
              expect(form).to have_content(template[:file_name])
              expect(form).to have_normalized_ws_text(template[:content].chomp)
              expect(form).to have_content('Add new file')
            end
          end
        end
      end

      def set_file_template_if_not_already_set
        response = get Runtime::API::Request.new(@api_client, "/groups/#{@group.id}").url

        return if parse_body(response)[:file_template_project_id]

        @group.visit!
        Page::Group::Menu.perform(&:click_group_general_settings_item)
        Page::Group::Settings::General.perform do |general|
          general.choose_file_template_repository(@file_template_project.name)
        end
      end

      def remove_group_file_template_if_set
        response = get Runtime::API::Request.new(@api_client, "/groups/#{@group.id}").url

        if parse_body(response)[:file_template_project_id]
          put Runtime::API::Request.new(@api_client, "/groups/#{@group.id}").url, { file_template_project_id: nil }
        end
      end
    end
  end
end
