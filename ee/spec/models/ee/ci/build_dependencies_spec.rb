# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildDependencies do
  describe '#cross_project' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project, refind: true) { create(:project, :repository) }
    let(:dependencies) { }

    let(:pipeline) do
      create(:ci_pipeline,
        project: project,
        sha: project.commit.id,
        ref: project.default_branch,
        status: 'success')
    end

    let!(:job) do
      create(:ci_build,
        pipeline: pipeline,
        name: 'final',
        stage_idx: 3,
        stage: 'deploy',
        user: user,
        options: { cross_dependencies: dependencies })
    end

    subject { described_class.new(job).cross_project }

    before do
      project.add_developer(user)
      pipeline.update!(user: user)
      stub_licensed_features(cross_project_pipelines: true)
    end

    context 'when cross_dependencies are not defined' do
      it { is_expected.to be_empty }
    end

    context 'with missing dependency' do
      let(:dependencies) do
        [
          {
            project: 'some/project',
            job: 'some/job',
            ref: 'some/ref',
            artifacts: true
          }
        ]
      end

      it { is_expected.to be_empty }
    end

    context 'with cross_dependencies to the same project' do
      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: pipeline,
          name: 'dependency',
          stage_idx: 1,
          stage: 'build',
          user: user
        )
      end

      let(:dependencies) do
        [
          {
            project: project.full_path,
            job: 'dependency',
            ref: pipeline.ref,
            artifacts: artifacts
          }
        ]
      end

      context 'with artifacts true' do
        let(:artifacts) { true }

        it { is_expected.to contain_exactly(dependency) }
      end

      context 'with artifacts false' do
        let(:artifacts) { false }

        it { is_expected.to be_empty }
      end

      context 'with dependency names from environment variables' do
        before do
          job.yaml_variables.push(key: 'DEPENDENCY_NAME', value: 'dependency', public: true)
          job.save!
        end

        let(:dependencies) do
          [
            {
              project: '$CI_PROJECT_PATH',
              job: '$DEPENDENCY_NAME',
              ref: '$CI_COMMIT_BRANCH',
              artifacts: true
            }
          ]
        end

        it { is_expected.to contain_exactly(dependency) }
      end
    end

    context 'with cross_dependencies to another ref in same project' do
      let(:another_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: 'feature',
          status: 'success')
      end

      let(:dependencies) do
        [
          {
            project: project.full_path,
            job: 'dependency',
            ref: another_pipeline.ref,
            artifacts: true
          }
        ]
      end

      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: another_pipeline,
          ref: another_pipeline.ref,
          name: 'dependency',
          stage_idx: 4,
          stage: 'deploy',
          user: user
        )
      end

      it { is_expected.to contain_exactly(dependency) }
    end

    context 'with cross_dependencies to a pipeline in another project' do
      let(:other_project) { create(:project, :repository) }

      let(:other_pipeline) do
        create(:ci_pipeline,
          project: other_project,
          sha: other_project.commit.id,
          ref: other_project.default_branch,
          status: 'success',
          user: user)
      end

      let(:feature_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: 'feature',
          status: 'success')
      end

      let(:dependencies) do
        [
          {
            project: other_project.full_path,
            job: 'other_dependency',
            ref: other_pipeline.ref,
            artifacts: true
          },
          {
            project: project.full_path,
            job: 'dependency',
            ref: feature_pipeline.ref,
            artifacts: true
          }
        ]
      end

      let!(:other_dependency) do
        create(:ci_build, :success,
          pipeline: other_pipeline,
          ref: other_pipeline.ref,
          name: 'other_dependency',
          stage_idx: 4,
          stage: 'deploy',
          user: user)
      end

      let!(:dependency) do
        create(:ci_build, :success,
          pipeline: feature_pipeline,
          ref: feature_pipeline.ref,
          name: 'dependency',
          stage_idx: 4,
          stage: 'deploy',
          user: user)
      end

      context 'with permissions to other_project' do
        before do
          other_project.add_developer(user)
        end

        it 'contains both dependencies' do
          is_expected.to contain_exactly(dependency, other_dependency)
        end

        context 'when license does not have cross_project_pipelines' do
          before do
            stub_licensed_features(cross_project_pipelines: false)
          end

          it { expect(subject).to be_empty }
        end
      end

      context 'without permissions to other_project' do
        it { is_expected.to contain_exactly(dependency) }
      end
    end

    context 'with both cross project and cross pipeline dependencies' do
      let(:other_project) { create(:project, :repository) }

      let(:other_project_pipeline) do
        create(:ci_pipeline,
          project: other_project,
          sha: other_project.commit.id,
          ref: other_project.default_branch,
          status: 'success',
          user: user)
      end

      let!(:cross_project_dependency) do
        create(:ci_build, :success,
          pipeline: other_project_pipeline,
          ref: other_project_pipeline.ref,
          name: 'deploy',
          stage_idx: 4,
          stage: 'deploy',
          user: user)
      end

      let(:upstream_pipeline) do
        create(:ci_pipeline,
          project: project,
          sha: project.commit.id,
          ref: project.default_branch,
          status: 'success',
          user: user)
      end

      let!(:upstream_pipeline_dependency) do
        create(:ci_build, :success,
          pipeline: upstream_pipeline,
          ref: upstream_pipeline.ref,
          name: 'build',
          stage_idx: 1,
          stage: 'build',
          user: user)
      end

      let(:dependencies) do
        [
          { pipeline: '$UPSTREAM_PIPELINE_ID', job: 'build', artifacts: true },
          { project: other_project.full_path, ref: other_project.default_branch, job: 'deploy', artifacts: true }
        ]
      end

      before do
        job.yaml_variables.push(key: 'UPSTREAM_PIPELINE_ID', value: upstream_pipeline.id.to_s, public: true)
        job.save!

        other_project.add_developer(user)
      end

      # TODO: In a follow-up MR we are adding support to querying pipelines in the same
      # project.
      it 'temporarily ignores cross pipeline dependencies' do
        is_expected.to contain_exactly(cross_project_dependency)
      end
    end

    context 'with too many cross_dependencies' do
      let(:cross_dependencies_limit) do
        ::Gitlab::Ci::Config::Entry::Needs::NEEDS_CROSS_PROJECT_DEPENDENCIES_LIMIT
      end

      before do
        cross_dependencies_limit.next.times do |index|
          create(:ci_build, :success,
            pipeline: pipeline, name: "dependency-#{index}",
            stage_idx: 1, stage: 'build', user: user
          )
        end
      end

      let(:dependencies) do
        Array.new(cross_dependencies_limit.next) do |index|
          {
            project: project.full_path,
            job: "dependency-#{index}",
            ref: pipeline.ref,
            artifacts: true
          }
        end
      end

      it 'returns a limited number of dependencies' do
        expect(subject.size).to eq(cross_dependencies_limit)
      end
    end
  end
end
