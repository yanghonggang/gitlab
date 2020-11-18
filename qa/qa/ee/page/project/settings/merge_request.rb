# frozen_string_literal: true

module QA
  module EE
    module Page
      module Project
        module Settings
          module MergeRequest
            extend QA::Page::PageConcern

            def self.prepended(base)
              super

              base.class_eval do
                include Page::Component::SecureReport

                view 'ee/app/views/projects/_merge_pipelines_settings.html.haml' do
                  element :merged_results_pipeline_checkbox
                end

                view 'ee/app/views/projects/_merge_trains_settings.html.haml' do
                  element :merge_trains_checkbox
                end
              end
            end

            def click_pipelines_for_merged_results_checkbox
              check_element :merged_results_pipeline_checkbox
            end

            def click_merge_trains_checkbox
              check_element :merge_trains_checkbox
            end

            def enable_merge_train
              click_pipelines_for_merged_results_checkbox
              click_merge_trains_checkbox
              click_save_changes
            end
          end
        end
      end
    end
  end
end
