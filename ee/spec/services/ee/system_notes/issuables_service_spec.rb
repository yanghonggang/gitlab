# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::IssuablesService do
  let_it_be(:group)    { create(:group) }
  let_it_be(:project)  { create(:project, :repository, group: group) }
  let_it_be(:author)   { create(:user) }

  let(:noteable) { create(:issue, project: project) }
  let(:issue)    { noteable }
  let(:epic)     { create(:epic, group: group) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '#change_health_status_note' do
    subject { service.change_health_status_note }

    context 'when health_status changed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: 'at_risk') }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed health status to **at risk**"
      end
    end

    context 'when health_status removed' do
      let(:noteable) { create(:issue, project: project, title: 'Lorem ipsum', health_status: nil) }

      it_behaves_like 'a system note' do
        let(:action) { 'health_status' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the health status'
      end
    end

    it 'tracks the issue event in usage ping' do
      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_health_status_changed_action).with(author: author)

      subject
    end
  end

  describe '#publish_issue_to_status_page' do
    let_it_be(:noteable) { create(:issue, project: project) }

    subject { service.publish_issue_to_status_page }

    it_behaves_like 'a system note' do
      let(:action) { 'published' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'published this issue to the status page'
    end
  end
end
