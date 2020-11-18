# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipeline', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    stub_feature_flags(graphql_pipeline_details: false)
    sign_in(user)

    project.add_developer(user)
  end

  describe 'GET /:project/pipelines/:id' do
    let(:pipeline) { create(:ci_pipeline, :with_job, project: project, ref: 'master', sha: project.commit.id, user: user) }

    subject { visit project_pipeline_path(project, pipeline) }

    context 'triggered and triggered by pipelines' do
      let(:upstream_pipeline) { create(:ci_pipeline, :with_job) }
      let(:downstream_pipeline) { create(:ci_pipeline, :with_job) }

      before do
        upstream_pipeline.project.add_developer(user)
        downstream_pipeline.project.add_developer(user)

        create_link(upstream_pipeline, pipeline)
        create_link(pipeline, downstream_pipeline)
      end

      it 'renders upstream pipeline' do
        subject

        expect(page).to have_content(upstream_pipeline.id)
        expect(page).to have_content(upstream_pipeline.project.name)
      end

      context 'expands the upstream pipeline on click' do
        it 'expands the upstream on click' do
          subject

          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click
          wait_for_requests
          expect(page).to have_selector(".js-upstream-pipeline-#{upstream_pipeline.id}")
        end

        it 'closes the expanded upstream on click' do
          subject

          # open
          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click
          wait_for_requests

          # close
          page.find(".js-pipeline-expand-#{upstream_pipeline.id}").click

          expect(page).not_to have_selector(".js-upstream-pipeline-#{upstream_pipeline.id}")
        end
      end

      it 'renders downstream pipeline' do
        subject

        expect(page).to have_content(downstream_pipeline.id)
        expect(page).to have_content(downstream_pipeline.project.name)
      end

      context 'expands the downstream pipeline on click' do
        it 'expands the downstream on click' do
          subject

          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click
          wait_for_requests
          expect(page).to have_selector(".js-downstream-pipeline-#{downstream_pipeline.id}")
        end

        it 'closes the expanded downstream on click' do
          subject

          # open
          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click
          wait_for_requests

          # close
          page.find(".js-pipeline-expand-#{downstream_pipeline.id}").click

          expect(page).not_to have_selector(".js-downstream-pipeline-#{downstream_pipeline.id}")
        end
      end
    end
  end

  describe 'GET /:project/pipelines/:id/security' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      stub_licensed_features(sast: true, security_dashboard: true)
    end

    context 'with a sast artifact' do
      before do
        create(:ee_ci_build, :sast, pipeline: pipeline)
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Security')
        expect(page).to have_css('#js-tab-security')
      end

      it 'shows security dashboard' do
        expect(page).to have_css('.js-security-dashboard-table')
      end
    end

    context 'without sast artifact' do
      before do
        visit security_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(current_path).to eq(pipeline_path(pipeline))
        expect(page).not_to have_css('#js-tab-security')
        expect(page).to have_selector('.pipeline-visualization')
      end
    end
  end

  describe 'GET /:project/pipelines/:id/licenses' do
    let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

    before do
      stub_licensed_features(license_scanning: true)
    end

    context 'with a License Compliance artifact' do
      before do
        create(:ee_ci_build, :license_scanning, pipeline: pipeline)

        visit licenses_project_pipeline_path(project, pipeline)
      end

      it 'shows jobs tab pane as active' do
        expect(page).to have_content('Licenses')
        expect(page).to have_css('#js-tab-licenses')
        expect(find('.js-licenses-counter')).to have_content('4')
      end

      it 'shows security report section' do
        expect(page).to have_content('Loading License Compliance report')
      end
    end

    context 'without License Compliance artifact' do
      before do
        visit licenses_project_pipeline_path(project, pipeline)
      end

      it 'displays the pipeline graph' do
        expect(current_path).to eq(pipeline_path(pipeline))
        expect(page).not_to have_content('Licenses')
        expect(page).to have_selector('.pipeline-visualization')
      end
    end
  end

  describe 'GET /:project/pipelines/:id/codequality_report' do
    shared_examples_for 'full codequality report' do
      context 'with no code quality artifact' do
        before do
          create(:ee_ci_build, pipeline: pipeline)
          visit project_pipeline_path(project, pipeline)
        end

        it 'does not show code quality tab' do
          expect(page).not_to have_content('Code Quality')
          expect(page).not_to have_css('#js-tab-codequality')
        end
      end

      context 'with code quality artifact' do
        before do
          create(:ee_ci_build, :codequality, pipeline: pipeline)
          visit codequality_report_project_pipeline_path(project, pipeline)
        end

        it 'shows code quality tab pane as active' do
          expect(page).to have_content('Code Quality')
          expect(page).to have_css('#js-tab-codequality')
        end

        it 'shows code quality report section' do
          expect(page).to have_content('Loading codeclimate report')
        end

        it 'shows code quality issue with link to file' do
          wait_for_requests

          expect(page).to have_content('Function `simulateEvent` has 28 lines of code (exceeds 25 allowed). Consider refactoring.')
          expect(find_link('app/assets/javascripts/test_utils/simulate_drag.js:1')[:href]).to end_with(project_blob_path(project, File.join(pipeline.commit.id, 'app/assets/javascripts/test_utils/simulate_drag.js')) + '#L1')
        end

        it 'contains events for data tracking', :aggregate_failures do
          expect(page).to have_selector('[data-track-event="click_button"]')
          expect(page).to have_selector('[data-track-label="get_codequality_report"]')
        end
      end
    end

    context 'for a branch pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: project, ref: 'master', sha: project.commit.id) }

      it_behaves_like 'full codequality report'
    end

    context 'for a merge request pipeline' do
      let(:merge_request) do
        create(:merge_request,
          :with_merge_request_pipeline,
          source_project: project,
          target_project: project,
          merge_sha: project.commit.id)
      end

      let(:pipeline) do
        merge_request.all_pipelines.last
      end

      it_behaves_like 'full codequality report'
    end
  end

  private

  def create_link(source_pipeline, pipeline)
    source_pipeline.sourced_pipelines.create!(
      source_job: source_pipeline.builds.all.sample,
      source_project: source_pipeline.project,
      project: pipeline.project,
      pipeline: pipeline
    )
  end
end
