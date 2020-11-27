# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New project', :js do
  let(:user) { create(:admin) }

  before do
    sign_in(user)
  end

  context 'repository mirrors' do
    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'shows mirror repository checkbox enabled', :js do
        visit new_project_path
        find('[data-qa-selector="import_project_link"]').click
        first('.js-import-git-toggle-button').click

        expect(page).to have_unchecked_field('Mirror repository', disabled: false)
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not show mirror repository option' do
        visit new_project_path
        find('[data-qa-selector="import_project_link"]').click
        first('.js-import-git-toggle-button').click

        expect(page).not_to have_content('Mirror repository')
      end
    end
  end

  context 'CI/CD for external repositories', :js do
    let(:repo) do
      OpenStruct.new(
        id: 123,
        login: 'some-github-repo',
        owner: OpenStruct.new(login: 'some-github-repo'),
        name: 'some-github-repo',
        full_name: 'my-user/some-github-repo',
        clone_url: 'https://github.com/my-user/some-github-repo.git'
      )
    end

    context 'when licensed' do
      before do
        stub_licensed_features(ci_cd_projects: true)
        stub_feature_flags(remove_legacy_github_client: false)
      end

      it 'shows CI/CD tab and pane' do
        visit new_project_path

        expect(page).to have_css('[data-qa-selector="cicd_for_external_repo_link"]')

        find('[data-qa-selector="cicd_for_external_repo_link"]').click

        expect(page).to have_css('#ci-cd-project-pane')
      end

      it '"Import project" tab creates projects with features enabled' do
        visit new_project_path
        find('[data-qa-selector="import_project_link"]').click

        page.within '#import-project-pane' do
          first('.js-import-git-toggle-button').click

          fill_in 'project_import_url', with: 'http://foo.git'
          fill_in 'project_name', with: 'import-project-with-features1'
          fill_in 'project_path', with: 'import-project-with-features1'
          choose 'project_visibility_level_20'
          click_button 'Create project'

          created_project = Project.last

          expect(current_path).to eq(project_import_path(created_project))
          expect(created_project.project_feature).to be_issues_enabled
        end
      end

      it 'creates CI/CD project from repo URL', :sidekiq_might_not_need_inline do
        visit new_project_path
        find('[data-qa-selector="cicd_for_external_repo_link"]').click

        page.within '#ci-cd-project-pane' do
          find('.js-import-git-toggle-button').click

          fill_in 'project_import_url', with: 'http://foo.git'
          fill_in 'project_name', with: 'CI CD Project1'
          fill_in 'project_path', with: 'ci-cd-project1'
          choose 'project_visibility_level_20'
          click_button 'Create project'

          created_project = Project.last
          expect(current_path).to eq(project_path(created_project))
          expect(created_project.mirror).to eq(true)
          expect(created_project.project_feature).not_to be_issues_enabled
        end
      end

      it 'creates CI/CD project from GitHub' do
        visit new_project_path
        find('[data-qa-selector="cicd_for_external_repo_link"]').click

        page.within '#ci-cd-project-pane' do
          find('.js-import-github').click
        end

        expect(page).to have_text('Authenticate with GitHub')

        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repos).and_return([repo])

        fill_in 'personal_access_token', with: 'fake-token'
        click_button 'Authenticate'
        wait_for_requests

        # Mock the POST `/import/github`
        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repository).and_return(repo)
        project = create(:project, name: 'some-github-repo', creator: user, import_type: 'github')
        create(:import_state, :finished, import_url: repo.clone_url, project: project)
        allow_any_instance_of(CiCd::SetupProject).to receive(:setup_external_service)
        CiCd::SetupProject.new(project, user).execute
        allow_any_instance_of(Gitlab::LegacyGithubImport::ProjectCreator)
          .to receive(:execute).with(hash_including(ci_cd_only: true))
          .and_return(project)

        click_button 'Connect'
        wait_for_requests

        expect(page).to have_text('Done')

        created_project = Project.last
        expect(created_project.name).to eq('some-github-repo')
        expect(created_project.mirror).to eq(true)
        expect(created_project.project_feature).not_to be_issues_enabled
      end

      it 'stays on GitHub import page after access token failure' do
        visit new_project_path
        find('[data-qa-selector="cicd_for_external_repo_link"]').click

        page.within '#ci-cd-project-pane' do
          find('.js-import-github').click
        end

        allow_any_instance_of(Gitlab::LegacyGithubImport::Client).to receive(:repos).and_raise(Octokit::Unauthorized)

        fill_in 'personal_access_token', with: 'unauthorized-fake-token'
        click_button 'Authenticate'

        expect(page).to have_text('Access denied to your GitHub account.')
        expect(page).to have_current_path(new_import_github_path(ci_cd_only: true))
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(ci_cd_projects: false)
      end

      it 'does not show CI/CD only tab' do
        visit new_project_path

        expect(page).not_to have_css('[data-qa-selector="cicd_for_external_repo_link"]')
      end
    end
  end

  context 'Group-level project templates', :js do
    def visit_create_from_group_template_tab
      visit url
      click_link 'Create from template'

      page.within('#create-from-template-pane') do
        click_link 'Group'
        wait_for_all_requests
      end
    end

    let(:url) { new_project_path }

    context 'when licensed' do
      before do
        stub_licensed_features(custom_project_templates: true, group_project_templates: true)
      end

      it 'shows Group tab in Templates section' do
        visit url
        click_link 'Create from template'

        expect(page).to have_css('.custom-group-project-templates-tab')
      end

      shared_examples 'group templates displayed' do
        before do
          visit_create_from_group_template_tab
        end

        it 'the tab badge displays the number of templates available' do
          page.within('.custom-group-project-templates-tab') do
            expect(page).to have_selector('span.badge', text: template_number)
          end
        end

        it 'the tab shows the list of templates available' do
          page.within('#custom-group-project-templates') do
            # Show templates in case they're collapsed
            page.all(:xpath, "//div[@class='js-template-group-options template-group-options']", wait: false).each(&:click)

            expect(page).to have_selector('.template-option', count: template_number)
          end
        end
      end

      shared_examples 'template selected' do
        before do
          visit_create_from_group_template_tab

          page.within('.custom-project-templates') do
            page.find(".template-option input[value='#{subgroup1_project1.id}']").first(:xpath, './/..').click
            wait_for_all_requests
          end
        end

        context 'when template is selected' do
          context 'namespace selector' do
            it "only shows the template's group hierarchy options" do
              page.within('#create-from-template-pane') do
                elements = page.find_all("#project_namespace_id option:not(.hidden)", visible: false).map { |e| e['data-name'] }
                expect(elements).to contain_exactly(group1.name, subgroup1.name, subsubgroup1.name)
              end
            end

            it 'does not show the user namespace options' do
              page.within('#create-from-template-pane') do
                expect(page.find_all("#project_namespace_id optgroup.hidden[label='Users']", visible: false)).not_to be_empty
              end
            end
          end
        end

        context 'when user changes template' do
          let(:url) { new_project_path }

          before do
            page.within('#create-from-template-pane') do
              click_button 'Change template'

              page.find(:xpath, "//input[@type='radio' and @value='#{subgroup1_project1.id}']/..").click

              wait_for_all_requests
            end
          end

          it 'list the appropriate groups' do
            page.within('#create-from-template-pane') do
              elements = page.find_all("#project_namespace_id option:not(.hidden)", visible: false).map { |e| e['data-name'] }

              expect(elements).to contain_exactly(group1.name, subgroup1.name, subsubgroup1.name)
            end
          end
        end
      end

      context 'when custom project group template is set' do
        let(:group1) { create(:group) }
        let(:group2) { create(:group) }
        let(:group3) { create(:group) }
        let(:group4) { create(:group) }
        let(:subgroup1) { create(:group, parent: group1) }
        let(:subgroup2) { create(:group, parent: group2) }
        let(:subgroup4) { create(:group, parent: group4) }
        let(:subsubgroup1) { create(:group, parent: subgroup1) }
        let(:subsubgroup4) { create(:group, parent: subgroup4) }
        let!(:subgroup1_project1) { create(:project, namespace: subgroup1) }
        let!(:subgroup1_project2) { create(:project, namespace: subgroup1) }
        let!(:subgroup2_project) { create(:project, namespace: subgroup2) }
        let!(:subsubgroup1_project) { create(:project, namespace: subsubgroup1) }
        let!(:subsubgroup4_project1) { create(:project, namespace: subsubgroup4) }
        let!(:subsubgroup4_project2) { create(:project, namespace: subsubgroup4) }

        before do
          group1.add_owner(user)
          group2.add_owner(user)
          group3.add_owner(user)
          group4.add_owner(user)
          group1.update!(custom_project_templates_group_id: subgroup1.id)
          group2.update!(custom_project_templates_group_id: subgroup2.id)
          subgroup4.update!(custom_project_templates_group_id: subsubgroup4.id)
        end

        context 'when top level context' do
          it_behaves_like 'group templates displayed' do
            let(:template_number) { 5 }
          end

          it_behaves_like 'template selected'
        end

        context 'when namespace context' do
          let(:url) { new_project_path(namespace_id: group1.id) }

          it_behaves_like 'group templates displayed' do
            let(:template_number) { 2 }
          end

          it_behaves_like 'template selected'
        end

        context 'when creating project from subgroup when template set on top-level group' do
          let(:url) { new_project_path(namespace_id: subgroup1.id) }

          it_behaves_like 'group templates displayed' do
            let(:template_number) { 2 }
          end

          it_behaves_like 'template selected'
        end

        context 'when creating project from top-level group when template set on a sub-subgroup' do
          let(:url) { new_project_path(namespace_id: group4.id) }

          it_behaves_like 'group templates displayed' do
            let(:template_number) { 0 }
          end
        end

        context 'when using a Group without a custom project template' do
          let(:url) { new_project_path(namespace_id: group3.id) }

          before do
            visit_create_from_group_template_tab
          end

          it 'shows a total of 0 templates' do
            page.within('.custom-group-project-templates-tab') do
              expect(page).to have_selector('span.badge', text: 0)
            end
          end

          it 'does not list any templates' do
            page.within('#custom-group-project-templates') do
              expect(page).to have_selector('.template-option', count: 0)
            end
          end
        end

        context 'when namespace is supposed to be checked' do
          context 'when in proper plan' do
            context 'when creating project from top-level group with templates' do
              let(:url) { new_project_path(namespace_id: group1.id) }

              before do
                allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
                create(:gitlab_subscription, :gold, namespace: group1)
              end

              it 'show Group tab in Templates section' do
                visit url
                click_link 'Create from template'

                expect(page).to have_css('.custom-group-project-templates-tab')
              end

              it_behaves_like 'group templates displayed' do
                let(:template_number) { 2 }
              end
            end
          end

          context 'when not in proper plan' do
            let(:url) { new_project_path(namespace_id: group1.id) }

            before do
              stub_application_setting(check_namespace_plan: true)
              create(:gitlab_subscription, :bronze, namespace: group1)
            end

            it 'show Group tab in Templates section' do
              visit url
              click_link 'Create from template'

              expect(page).to have_css('.custom-group-project-templates-tab')
            end

            it_behaves_like 'group templates displayed' do
              let(:template_number) { 0 }
            end
          end
        end
      end

      context 'when group template is not set' do
        it_behaves_like 'group templates displayed' do
          let(:template_number) { 0 }
        end
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(custom_project_templates: false)
      end

      it 'does not show Group tab in Templates section' do
        visit url
        click_link 'Create from template'

        expect(page).not_to have_css('.custom-group-project-templates-tab')
      end
    end
  end

  context 'Built-in project templates' do
    let(:enterprise_templates) { Gitlab::ProjectTemplate.localized_ee_templates_table }

    context 'when `enterprise_templates` is licensed', :js do
      before do
        stub_licensed_features(enterprise_templates: true)
      end

      it 'shows enterprise templates' do
        visit_create_from_built_in_templates_tab

        enterprise_templates.each do |template|
          expect(page).to have_content(template.title)
          expect(page).to have_link('Preview', href: template.preview)
        end
      end
    end

    context 'when `enterprise_templates` is unlicensed', :js do
      before do
        stub_licensed_features(enterprise_templates: false)
      end

      it 'does not show enterprise templates' do
        visit_create_from_built_in_templates_tab

        enterprise_templates.each do |template|
          expect(page).not_to have_content(template.title)
          expect(page).not_to have_link('Preview', href: template.preview)
        end
      end
    end

    private

    def visit_create_from_built_in_templates_tab
      visit new_project_path

      find('[data-qa-selector="create_from_template_link"]').click
    end
  end
end
