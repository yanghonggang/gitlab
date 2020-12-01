# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsHelper do
  include ActionView::Helpers::UrlHelper
  include ProjectForksHelper

  describe '#state_name_with_icon' do
    using RSpec::Parameterized::TableSyntax

    let(:merge_request) { MergeRequest.new }

    where(:state, :expected_name, :expected_icon) do
      :merged? | 'Merged' | 'git-merge'
      :closed? | 'Closed' | 'close'
      :opened? | 'Open' | 'issue-open-m'
    end

    with_them do
      before do
        allow(merge_request).to receive(state).and_return(true)
      end

      it 'returns name and icon' do
        name, icon = helper.state_name_with_icon(merge_request)

        expect(name).to eq(expected_name)
        expect(icon).to eq(expected_icon)
      end
    end
  end

  describe '#format_mr_branch_names' do
    describe 'within the same project' do
      let(:merge_request) { create(:merge_request) }

      subject { format_mr_branch_names(merge_request) }

      it { is_expected.to eq([merge_request.source_branch, merge_request.target_branch]) }
    end

    describe 'within different projects' do
      let(:project) { create(:project) }
      let(:forked_project) { fork_project(project) }
      let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }
      subject { format_mr_branch_names(merge_request) }

      let(:source_title) { "#{forked_project.full_path}:#{merge_request.source_branch}" }
      let(:target_title) { "#{project.full_path}:#{merge_request.target_branch}" }

      it { is_expected.to eq([source_title, target_title]) }
    end
  end

  describe '#tab_link_for' do
    let(:merge_request) { create(:merge_request, :simple) }
    let(:options) { {} }

    subject { tab_link_for(merge_request, :show, options) { 'Discussion' } }

    describe 'supports the :force_link option' do
      let(:options) { { force_link: true } }

      it 'removes the data-toggle attributes' do
        is_expected.not_to match(/data-toggle="tabvue"/)
      end
    end
  end
end
