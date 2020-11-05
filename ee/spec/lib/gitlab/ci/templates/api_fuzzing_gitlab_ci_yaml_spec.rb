# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'API-Fuzzing.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('API-Fuzzing') }

  describe 'the template file' do
    let(:template_filename) { Rails.root.join("lib/gitlab/ci/templates/" + template.full_name) }
    let(:contents) { File.read(template_filename) }
    let(:production_registry) { 'registry.gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing:${FUZZAPI_VERSION}-engine' }
    let(:staging_registry) { 'registry.gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src:${FUZZAPI_VERSION}-engine' }

    # Make sure future changes to the template use the production container registry.
    #
    # The API Fuzzing template is developed against a dev container registry.
    # The registry is switched when releasing new versions. The difference in
    # names between development and production is also quite small making it
    # easy to miss during review.
    it 'uses the production repository' do
      expect( contents.include?(production_registry) ).to be true
    end

    it 'doesn\'t use the staging repository' do
      expect( contents.include?(staging_registry) ).to be false
    end
  end

  describe 'the created pipeline' do
    let(:user) { create(:admin) }
    let(:default_branch) { 'master' }
    let(:pipeline_branch) { default_branch }
    let(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push) }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
      allow_any_instance_of(Ci::BuildScheduleWorker).to receive(:perform).and_return(true)
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when project has no license' do
      before do
        create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
        create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
      end

      it 'includes job to display error' do
        expect(build_names).to match_array(%w[apifuzzer_fuzz_unlicensed])
      end
    end

    context 'when project has Ultimate license' do
      let(:license) { create(:license, plan: License::ULTIMATE_PLAN) }

      before do
        allow(License).to receive(:current).and_return(license)
      end

      context 'by default' do
        it 'includes a job' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz])
        end
      end

      context 'when configured with HAR' do
        before do
          create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
          create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
        end

        it 'includes job' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz])
        end
      end

      context 'when configured with OpenAPI' do
        before do
          create(:ci_variable, project: project, key: 'FUZZAPI_OPENAPI', value: 'testing.json')
          create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
        end

        it 'includes job' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz])
        end
      end

      context 'when configured with Postman' do
        before do
          create(:ci_variable, project: project, key: 'FUZZAPI_POSTMAN_COLLECTION', value: 'testing.json')
          create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
        end

        it 'includes job' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz])
        end
      end

      context 'when FUZZAPI_D_TARGET_IMAGE is present' do
        before do
          create(:ci_variable, project: project, key: 'FUZZAPI_D_TARGET_IMAGE', value: 'imagename:latest')
          create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
          create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
        end

        it 'includes dnd job' do
          expect(build_names).to match_array(%w[apifuzzer_fuzz_dnd])
        end
      end
    end

    context 'when API_FUZZING_DISABLED=1' do
      before do
        create(:ci_variable, project: project, key: 'API_FUZZING_DISABLED', value: '1')
        create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
        create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
      end

      it 'includes no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
      end
    end

    context 'when API_FUZZING_DISABLED=1 with DnD' do
      before do
        create(:ci_variable, project: project, key: 'API_FUZZING_DISABLED', value: '1')
        create(:ci_variable, project: project, key: 'FUZZAPI_D_TARGET_IMAGE', value: 'imagename:latest')
        create(:ci_variable, project: project, key: 'FUZZAPI_HAR', value: 'testing.har')
        create(:ci_variable, project: project, key: 'FUZZAPI_TARGET_URL', value: 'http://example.com')
      end

      it 'includes no jobs' do
        expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
      end
    end
  end
end
