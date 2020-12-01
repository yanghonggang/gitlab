# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :public, :repository) }
  let_it_be(:project_snippet) { create(:project_snippet, :public, :repository, project: project) }

  context 'when repository container is a project' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project }
      let(:user) { project.owner }
      let(:access_checker_class) { Gitlab::GitAccess }

      describe 'POST #git_upload_pack' do
        before do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)
        end

        def send_request
          post :git_upload_pack, params: params
        end

        context 'on a read-only instance' do
          before do
            allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          end

          it 'does not update project statistics' do
            expect(ProjectDailyStatisticsWorker).not_to receive(:perform_async)

            send_request
          end
        end

        context 'when project_statistics_sync feature flag is disabled' do
          before do
            stub_feature_flags(project_statistics_sync: false)
          end

          it 'updates project statistics async for projects' do
            expect(ProjectDailyStatisticsWorker).to receive(:perform_async)

            send_request
          end
        end

        it 'updates project statistics sync for projects' do
          expect { send_request }.to change {
            Projects::DailyStatisticsFinder.new(container).total_fetch_count
          }.from(0).to(1)
        end
      end
    end
  end

  context 'when repository container is a project wiki' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { create(:project_wiki, :empty_repo, project: project) }
      let(:user) { project.owner }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'when repository container is a personal snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { personal_snippet }
      let(:user) { personal_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }
    end
  end

  context 'when repository container is a project snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project_snippet }
      let(:user) { project_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }
    end
  end
end
