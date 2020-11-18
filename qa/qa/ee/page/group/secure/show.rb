# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Secure
          class Show < QA::Page::Base
            include Page::Component::SecureReport

            view 'ee/app/assets/javascripts/security_dashboard/components/security_dashboard_table.vue' do
              element :security_report_content, required: true
            end

            view 'ee/app/assets/javascripts/security_dashboard/components/first_class_vulnerability_severities.vue' do
              element :project_name_text, required: true
            end

            def filter_project(project)
              click_element(:filter_project_dropdown)
              within_element(:filter_dropdown_content) do
                click_on project
              end
            end

            def has_security_status_project_for_severity?(severity, project)
              within_element("severity_accordion_item_#{severity}") do
                click_on severity
              end
              has_element?(:project_name_text, text: "#{project.group.sandbox.path} / #{project.group.path} / #{project.name}")
            end
          end
        end
      end
    end
  end
end
