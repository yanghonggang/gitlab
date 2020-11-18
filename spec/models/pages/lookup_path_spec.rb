# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::LookupPath do
  let(:project) { create(:project, :pages_private, pages_https_only: true) }

  subject(:lookup_path) { described_class.new(project) }

  before do
    stub_pages_setting(access_control: true, external_https: ["1.1.1.1:443"])
    stub_artifacts_object_storage
    stub_pages_object_storage(::Pages::DeploymentUploader)
  end

  describe '#project_id' do
    it 'delegates to Project#id' do
      expect(lookup_path.project_id).to eq(project.id)
    end
  end

  describe '#access_control' do
    it 'delegates to Project#private_pages?' do
      expect(lookup_path.access_control).to eq(true)
    end
  end

  describe '#https_only' do
    subject(:lookup_path) { described_class.new(project, domain: domain) }

    context 'when no domain provided' do
      let(:domain) { nil }

      it 'delegates to Project#pages_https_only?' do
        expect(lookup_path.https_only).to eq(true)
      end
    end

    context 'when there is domain provided' do
      let(:domain) { instance_double(PagesDomain, https?: false) }

      it 'takes into account the https setting of the domain' do
        expect(lookup_path.https_only).to eq(false)
      end
    end
  end

  describe '#source' do
    let(:source) { lookup_path.source }

    shared_examples 'uses disk storage' do
      it 'uses disk storage', :aggregate_failures do
        expect(source[:type]).to eq('file')
        expect(source[:path]).to eq(project.full_path + "/public/")
      end
    end

    include_examples 'uses disk storage'

    context 'when there is pages deployment' do
      let(:deployment) { create(:pages_deployment, project: project) }

      before do
        project.mark_pages_as_deployed
        project.pages_metadatum.update!(pages_deployment: deployment)
      end

      it 'uses deployment from object storage' do
        Timecop.freeze do
          expect(source).to(
            eq({
                 type: 'zip',
                 path: deployment.file.url(expire_at: 1.day.from_now),
                 global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
                 sha256: deployment.file_sha256,
                 file_size: deployment.size,
                 file_count: deployment.file_count
               })
          )
        end
      end

      context 'when deployment is in the local storage' do
        before do
          deployment.file.migrate!(::ObjectStorage::Store::LOCAL)
        end

        it 'uses file protocol' do
          Timecop.freeze do
            expect(source).to(
              eq({
                   type: 'zip',
                   path: 'file://' + deployment.file.path,
                   global_id: "gid://gitlab/PagesDeployment/#{deployment.id}",
                   sha256: deployment.file_sha256,
                   file_size: deployment.size,
                   file_count: deployment.file_count
                 })
            )
          end
        end

        context 'when pages_serve_with_zip_file_protocol feature flag is disabled' do
          before do
            stub_feature_flags(pages_serve_with_zip_file_protocol: false)
          end

          include_examples 'uses disk storage'
        end
      end

      context 'when pages_serve_from_deployments feature flag is disabled' do
        before do
          stub_feature_flags(pages_serve_from_deployments: false)
        end

        include_examples 'uses disk storage'
      end
    end

    context 'when artifact_id from build job is present in pages metadata' do
      let(:artifacts_archive) { create(:ci_job_artifact, :zip, :remote_store, project: project) }

      before do
        project.mark_pages_as_deployed(artifacts_archive: artifacts_archive)
      end

      it 'uses artifacts object storage' do
        Timecop.freeze do
          expect(source).to(
            eq({
                 type: 'zip',
                 path: artifacts_archive.file.url(expire_at: 1.day.from_now),
                 global_id: "gid://gitlab/Ci::JobArtifact/#{artifacts_archive.id}",
                 sha256: artifacts_archive.file_sha256,
                 file_size: artifacts_archive.size,
                 file_count: nil
               })
          )
        end
      end

      context 'when artifact is not uploaded to object storage' do
        let(:artifacts_archive) { create(:ci_job_artifact, :zip) }

        it 'uses file protocol', :aggregate_failures do
          Timecop.freeze do
            expect(source).to(
              eq({
                   type: 'zip',
                   path: 'file://' + artifacts_archive.file.path,
                   global_id: "gid://gitlab/Ci::JobArtifact/#{artifacts_archive.id}",
                   sha256: artifacts_archive.file_sha256,
                   file_size: artifacts_archive.size,
                   file_count: nil
                 })
            )
          end
        end

        context 'when pages_serve_with_zip_file_protocol feature flag is disabled' do
          before do
            stub_feature_flags(pages_serve_with_zip_file_protocol: false)
          end

          include_examples 'uses disk storage'
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(pages_serve_from_artifacts_archive: false)
        end

        include_examples 'uses disk storage'
      end
    end
  end

  describe '#prefix' do
    it 'returns "/" for pages group root projects' do
      project = instance_double(Project, pages_group_root?: true)
      lookup_path = described_class.new(project, trim_prefix: 'mygroup')

      expect(lookup_path.prefix).to eq('/')
    end

    it 'returns the project full path with the provided prefix removed' do
      project = instance_double(Project, pages_group_root?: false, full_path: 'mygroup/myproject')
      lookup_path = described_class.new(project, trim_prefix: 'mygroup')

      expect(lookup_path.prefix).to eq('/myproject/')
    end
  end
end
