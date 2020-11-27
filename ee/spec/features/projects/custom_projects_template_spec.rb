# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project' do
  describe 'Custom instance-level projects templates' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let!(:projects) { create_list(:project, 3, :public, :metrics_dashboard_enabled, namespace: group) }

    before do
      stub_ee_application_setting(custom_project_templates_group_id: group.id)
    end

    describe 'when feature custom_project_templates is enabled' do
      before do
        stub_licensed_features(custom_project_templates: true)
        allow(Project).to receive(:default_per_page).and_return(2)

        sign_in user
        visit new_project_path
      end

      it 'shows built-in templates tab' do
        page.within '.project-template .built-in-tab' do
          expect(page).to have_content 'Built-in'
        end
      end

      it 'shows custom projects templates tab' do
        page.within '.project-template .custom-instance-project-templates-tab' do
          expect(page).to have_content 'Instance'
        end
      end

      it 'displays the number of projects templates available to the user' do
        page.within '.project-template .custom-instance-project-templates-tab span.badge' do
          expect(page).to have_content '3'
        end
      end

      it 'allows creation from custom project template', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        find('[data-qa-selector="create_from_template_link"]').click
        find('.project-template .custom-instance-project-templates-tab').click
        find("label[for='#{projects.first.name}']").click

        page.within '.project-fields-form' do
          fill_in("project_name", with: new_name)
          # Have to reset it to '' so it overwrites rather than appends
          fill_in('project_path', with: '')
          fill_in("project_path", with: new_path)

          Sidekiq::Testing.inline! do
            click_button "Create project"
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'allows creation from custom project template using only the name', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        find('[data-qa-selector="create_from_template_link"]').click
        find('.project-template .custom-instance-project-templates-tab').click
        find("label[for='#{projects.first.name}']").click

        page.within '.project-fields-form' do
          fill_in("project_name", with: new_name)

          Sidekiq::Testing.inline! do
            click_button "Create project"
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'allows creation from custom project template using only the path', :js do
        new_path = 'example-custom-project-template'
        new_name = 'Example Custom Project Template'

        find('[data-qa-selector="create_from_template_link"]').click
        find('.project-template .custom-instance-project-templates-tab').click
        find("label[for='#{projects.first.name}']").click

        page.within '.project-fields-form' do
          fill_in("project_path", with: new_path)

          Sidekiq::Testing.inline! do
            click_button "Create project"
          end
        end

        expect(page).to have_content new_name
        expect(Project.last.name).to eq new_name
        expect(page).to have_current_path "/#{user.username}/#{new_path}"
        expect(Project.last.path).to eq new_path
      end

      it 'has a working pagination', :js do
        last_project = "label[for='#{projects.last.name}']"

        find('[data-qa-selector="create_from_template_link"]').click
        find('.project-template .custom-instance-project-templates-tab').click

        expect(page).to have_css('.custom-project-templates .gl-pagination')
        expect(page).not_to have_css(last_project)

        find('.js-next-button a').click

        expect(page).to have_css(last_project)
      end
    end

    describe 'when feature custom_project_templates is disabled' do
      it 'does not show custom project templates tab' do
        expect(page).not_to have_css('.project-template .nav-tabs')
      end
    end
  end
end
