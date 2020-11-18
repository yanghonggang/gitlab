# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'search/_results' do
  let(:search_objects) { Issue.page(1).per(2) }
  let(:scope) { 'issues' }

  before do
    controller.params[:action] = 'show'

    create_list(:issue, 3)

    @search_objects = search_objects
    @scope = scope
    @search_term = 'foo'
  end

  it 'displays the page size' do
    render

    expect(rendered).to have_content('Showing 1 - 2 of 3 issues for foo')
  end

  context 'when search results do not have a count' do
    before do
      @search_objects = @search_objects.without_count
    end

    it 'does not display the page size' do
      render

      expect(rendered).not_to have_content(/Showing .* of .*/)
    end
  end

  context 'rendering all types of search results' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:issue) { create(:issue, project: project, title: '*') }
    let_it_be(:merge_request) { create(:merge_request, title: '*', source_project: project, target_project: project) }
    let_it_be(:milestone) { create(:milestone, title: '*', project: project) }
    let_it_be(:note) { create(:discussion_note_on_issue, project: project, note: '*') }
    let_it_be(:wiki_blob) { create(:wiki_page, project: project, content: '*') }
    let_it_be(:user) { create(:admin) }

    %w[issues merge_requests].each do |search_scope|
      context "when scope is #{search_scope}" do
        let(:scope) { search_scope }
        let(:search_objects) { Gitlab::ProjectSearchResults.new(user, '*', project: project).objects(scope) }

        it 'renders the click text event tracking attributes' do
          render

          expect(rendered).to have_selector('[data-track-event=click_text]')
          expect(rendered).to have_selector('[data-track-property=search_result]')
        end

        it 'does render the sidebar' do
          render

          expect(rendered).to have_selector('#js-search-sidebar')
        end
      end
    end

    %w[blobs notes wiki_blobs milestones].each do |search_scope|
      context "when scope is #{search_scope}" do
        let(:scope) { search_scope }
        let(:search_objects) { Gitlab::ProjectSearchResults.new(user, '*', project: project).objects(scope) }

        it 'renders the click text event tracking attributes' do
          render

          expect(rendered).to have_selector('[data-track-event=click_text]')
          expect(rendered).to have_selector('[data-track-property=search_result]')
        end

        it 'does not render the sidebar' do
          render

          expect(rendered).not_to have_selector('#js-search-sidebar')
        end
      end
    end
  end
end
