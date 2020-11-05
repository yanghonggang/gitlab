# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Pull mirror a repository over SSH with a private key' do
      let(:source) do
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project_name = 'pull-mirror-source-project'
          project_push.file_name = 'README.md'
          project_push.file_content = '# This is a pull mirroring test project'
          project_push.commit_message = 'Add README.md'
        end
      end

      let(:source_project_uri) { source.project.repository_ssh_location.uri }
      let(:target_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pull-mirror-target-project'
        end
      end

      before do
        Flow::Login.sign_in

        target_project.visit!
      end

      it 'configures and syncs a (pull) mirrored repository', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/401' do
        # Configure the target project to pull from the source project
        # And get the public key to be used as a deploy key
        Page::Project::Menu.perform(&:go_to_repository_settings)
        public_key = Page::Project::Settings::Repository.perform do |settings|
          settings.expand_mirroring_repositories do |mirror_settings|
            mirror_settings.repository_url = source_project_uri
            mirror_settings.mirror_direction = 'Pull'
            mirror_settings.authentication_method = 'SSH public key'
            mirror_settings.detect_host_keys
            mirror_settings.mirror_repository
            mirror_settings.public_key source_project_uri
          end
        end

        # Add the public key to the source project as a deploy key
        Resource::DeployKey.fabricate! do |deploy_key|
          deploy_key.project = source.project
          deploy_key.title = "pull mirror key #{Time.now.to_f}"
          deploy_key.key = public_key
        end

        # Sync the repositories
        target_project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)
        Page::Project::Settings::Repository.perform do |settings|
          settings.expand_mirroring_repositories do |mirror_settings|
            mirror_settings.update source_project_uri
          end
        end

        # Check that the target project has the commit from the source
        target_project.visit!
        Page::Project::Show.perform do |project|
          expect(project).to have_file('README.md')
          expect(project).to have_readme_content('This is a pull mirroring test project')
          expect(project).to have_text("Mirrored from #{masked_url(source_project_uri)}")
        end
      end

      def masked_url(url)
        url.user = '*****'
        url
      end
    end
  end
end
