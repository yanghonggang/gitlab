# frozen_string_literal: true
require 'securerandom'

module QA
  RSpec.describe 'Manage' do
    describe 'Project templates' do
      before(:all) do
        @files = [
          {
            name: 'file.txt',
            content: 'foo'
          },
          {
            name: 'README.md',
            content: 'bar'
          }
        ]

        @template_container_group_name = "instance-template-container-group-#{SecureRandom.hex(8)}"

        template_container_group = QA::Resource::Group.fabricate_via_api! do |group|
          group.path = @template_container_group_name
          group.description = 'Instance template container group'
        end

        @template_project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'template-project-1'
          project.group = template_container_group
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @template_project
          push.files = @files
          push.commit_message = 'Add test files'
        end
      end

      context 'built-in', :requires_admin do
        before do
          Flow::Login.sign_in_as_admin

          @group = Resource::Group.fabricate_via_api!
        end

        it 'successfully imports the project using template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/905' do
          built_in = 'Ruby on Rails'

          @group.visit!
          Page::Group::Show.perform(&:go_to_new_project)

          QA::Flow::Project.go_to_create_project_from_template

          Page::Project::New.perform do |new_page|
            expect(new_page).to have_text(built_in)
          end

          create_project_using_template(project_name: 'Project using built-in project template',
            namespace: Runtime::Namespace.name(reset_cache: false),
            template_name: built_in)

          Page::Project::Show.perform do |project|
            project.wait_for_import_success

            expect(project).to have_content("Initialized from '#{built_in}' project template")
            expect(project).to have_file(".ruby-version")
          end
        end
      end

      # This was originally quarantined only on staging
      # against the issue https://gitlab.com/gitlab-org/gitlab/-/issues/228624
      # Now quarantining against a new issue due to failures on master
      # If dequarantining, the original staging quarantine should be reverted
      # if still applicable.
      context 'instance level', :requires_admin, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/247874', type: :bug } do
        before do
          Flow::Login.sign_in_as_admin

          Support::Retrier.retry_until do
            Page::Main::Menu.perform(&:go_to_admin_area)
            Page::Admin::Menu.perform(&:go_to_template_settings)

            EE::Page::Admin::Settings::Templates.perform do |templates|
              templates.choose_custom_project_template("#{@template_container_group_name}")
            end

            Page::Admin::Menu.perform(&:go_to_template_settings)

            EE::Page::Admin::Settings::Templates.perform do |templates|
              templates.current_custom_project_template.include? @template_container_group_name
            end
          end

          Resource::Group.fabricate_via_api!.visit!

          Page::Group::Show.perform(&:go_to_new_project)

          QA::Flow::Project.go_to_create_project_from_template
        end

        it 'successfully imports the project using template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/914' do
          Page::Project::New.perform do |new_page|
            new_page.retry_until do
              new_page.go_to_create_from_template_instance_tab
              expect(new_page.instance_template_tab_badge_text).to eq "1"
              new_page.has_text?(@template_project.name)
            end
          end

          create_project_using_template(project_name: 'Project using instance level project template',
            namespace: Runtime::Namespace.path,
            template_name: @template_project.name)

          Page::Project::Show.perform do |project|
            project.wait_for_import_success

            @files.each do |file|
              expect(project).to have_file(file[:name])
            end
          end
        end
      end

      context 'group level', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/211528', type: :bug } do
        before do
          Flow::Login.sign_in

          Page::Main::Menu.perform(&:go_to_groups)
          Page::Dashboard::Groups.perform { |groups| groups.click_group(Runtime::Namespace.sandbox_name) }

          Page::Group::Menu.perform(&:click_settings)

          Page::Group::Settings::General.perform do |settings|
            settings.choose_custom_project_template("#{@template_container_group_name}")
          end

          Page::Group::Menu.perform(&:click_settings)

          Page::Group::Settings::General.perform do |settings|
            expect(settings.current_custom_project_template).to include @template_container_group_name
          end

          group = Resource::Group.fabricate_via_api!
          group.visit!

          Page::Group::Show.perform(&:go_to_new_project)

          QA::Flow::Project.go_to_create_project_from_template

          Page::Project::New.perform(&:go_to_create_from_template_group_tab)
        end

        it 'successfully imports the project using template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/915' do
          Page::Project::New.perform do |new_page|
            expect(new_page.group_template_tab_badge_text).to eq "1"
            expect(new_page).to have_text(@template_container_group_name)
            expect(new_page).to have_text(@template_project.name)
          end

          create_project_using_template(project_name: 'Project using group level project template',
            namespace: Runtime::Namespace.sandbox_name,
            template_name: @template_project.name)

          Page::Project::Show.perform do |project|
            project.wait_for_import_success

            @files.each do |file|
              expect(project).to have_file(file[:name])
            end
          end
        end
      end

      def create_project_using_template(project_name:, namespace:, template_name:)
        Page::Project::New.perform do |new_page|
          new_page.use_template_for_project(template_name)
          new_page.choose_namespace(namespace)
          new_page.choose_name("#{project_name} #{SecureRandom.hex(8)}")
          new_page.add_description("#{project_name}")
          new_page.set_visibility('Public')
          new_page.create_new_project
        end
      end
    end
  end
end
