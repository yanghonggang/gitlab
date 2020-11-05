# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesHelper do
  let_it_be(:user) { create(:user) }

  describe '#issuable_initial_data' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)
      stub_commonmark_sourcepos_disabled
    end

    context 'for an epic' do
      let_it_be(:epic) { create(:epic, author: user, description: 'epic text', confidential: true) }

      it 'returns the correct data' do
        @group = epic.group

        expected_data = {
          endpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}",
          epicLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/links",
          updateEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}.json",
          issueLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/issues",
          canUpdate: true,
          canDestroy: true,
          canAdmin: true,
          issuableRef: "&#{epic.iid}",
          markdownPreviewPath: "/groups/#{@group.full_path}/preview_markdown",
          markdownDocsPath: '/help/user/markdown',
          issuableTemplateNamesPath: '',
          lockVersion: epic.lock_version,
          fullPath: @group.full_path,
          groupPath: @group.path,
          initialTitleHtml: epic.title,
          initialTitleText: epic.title,
          initialDescriptionHtml: '<p data-sourcepos="1:1-1:9" dir="auto">epic text</p>',
          initialDescriptionText: 'epic text',
          initialTaskStatus: '0 of 0 tasks completed',
          projectsEndpoint: "/api/v4/groups/#{@group.id}/projects",
          confidential: epic.confidential
        }
        expect(helper.issuable_initial_data(epic)).to eq(expected_data)
      end
    end

    context 'for an issue' do
      let_it_be(:issue) { create(:issue, author: user, description: 'issue text') }

      it 'returns the correct data' do
        @project = issue.project

        expected_data = {
          canAdmin: true,
          publishedIncidentUrl: nil
        }
        expect(helper.issuable_initial_data(issue)).to include(expected_data)
      end

      context 'when published to a configured status page' do
        it 'returns the correct data that includes publishedIncidentUrl' do
          @project = issue.project

          expect(Gitlab::StatusPage::Storage).to receive(:details_url).with(issue).and_return('http://status.com')
          expect(helper.issuable_initial_data(issue)).to include(
            publishedIncidentUrl: 'http://status.com'
          )
        end
      end
    end

    describe '#gitlab_team_member_badge' do
      let(:user) { create(:user) }
      let(:issue) { build(:issue, author: user) }

      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      context 'when `:gitlab_employee_badge` feature flag is disabled' do
        include_context 'gitlab team member'

        before do
          stub_feature_flags(gitlab_employee_badge: false)
        end

        it 'returns nil' do
          expect(helper.gitlab_team_member_badge(issue.author)).to be_nil
        end
      end

      context 'when issue author is not a GitLab team member' do
        it 'returns nil' do
          expect(helper.gitlab_team_member_badge(issue.author)).to be_nil
        end
      end

      context 'when issue author is a GitLab team member' do
        include_context 'gitlab team member'

        it 'returns span with svg icon' do
          expect(helper.gitlab_team_member_badge(issue.author)).to have_selector('span > svg')
        end

        context 'when `css_class` parameter is passed' do
          it 'adds CSS classes' do
            expect(helper.gitlab_team_member_badge(issue.author, css_class: 'foo bar baz')).to have_selector('span.foo.bar.baz')
          end
        end
      end
    end

    describe '#issuable_meta_author_slot' do
      it 'invoked gitlab_team_member_badge method' do
        user = double

        expect(helper).to receive(:gitlab_team_member_badge).with(user, css_class: nil)

        helper.issuable_meta_author_slot(user)
      end
    end
  end
end
