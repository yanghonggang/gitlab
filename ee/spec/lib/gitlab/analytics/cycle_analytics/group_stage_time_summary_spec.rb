# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::GroupStageTimeSummary do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:project_2) { create(:project, :repository, namespace: group) }
  let_it_be(:user) { create(:user, :admin) }
  let(:from) { 1.day.ago }
  let(:to) { nil }
  let(:options) { { from: from, to: to, current_user: user } }

  subject { described_class.new(group, options: options).data }

  around do |example|
    freeze_time { example.run }
  end

  describe '#lead_time' do
    describe 'issuable filter parameters' do
      let_it_be(:label) { create(:group_label, group: group) }

      before do
        create(:closed_issue, project: project, created_at: 1.day.ago, closed_at: Time.zone.now, author: user, labels: [label])
      end

      context 'when `author_username` is given' do
        before do
          options[:author_username] = user.username
        end

        it 'returns the correct lead time' do
          expect(subject.first[:value]).to eq('1.0')
        end
      end

      context 'when unknown `author_username` is given' do
        before do
          options[:author_username] = 'unknown_user'
        end

        it 'returns `-`' do
          expect(subject.first[:value]).to eq('-')
        end
      end

      context 'when `label_name` is given' do
        before do
          options[:label_name] = [label.name]
        end

        it 'returns the correct lead time' do
          expect(subject.first[:value]).to eq('1.0')
        end
      end

      context 'when unknown `label_name` is given' do
        before do
          options[:label_name] = ['unknown_label']
        end

        it 'returns `-`' do
          expect(subject.first[:value]).to eq('-')
        end
      end
    end

    context 'with `from` date' do
      let(:from) { 6.days.ago }

      before do
        create(:closed_issue, project: project, created_at: 1.day.ago, closed_at: Time.zone.now)
        create(:closed_issue, project: project, created_at: 2.days.ago, closed_at: Time.zone.now)
        create(:closed_issue, project: project_2, created_at: 4.days.ago, closed_at: Time.zone.now)
      end

      it 'finds the lead time of issues created after it' do
        expect(subject.first[:value]).to eq('2.0')
      end

      context 'with subgroups' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project_3) { create(:project, namespace: subgroup) }

        before do
          create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now, project: project_3)
          create(:closed_issue, created_at: 5.days.ago, closed_at: Time.zone.now, project: project_3)
        end

        it 'finds the lead time of issues from them' do
          expect(subject.first[:value]).to eq('3.0')
        end
      end

      context 'with projects specified in options' do
        before do
          create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now, project: create(:project, namespace: group))
        end

        subject { described_class.new(group, options: { from: from, current_user: user, projects: [project.id, project_2.id] }).data }

        it 'finds the lead time of issues from those projects' do
          # Median of 1, 2, 4, not including new issue
          expect(subject.first[:value]).to eq('2.0')
        end
      end

      context 'when `from` and `to` parameters are provided' do
        let(:from) { 3.days.ago }
        let(:to) { Time.zone.now }

        it 'finds the lead time of issues from 3 days ago' do
          expect(subject.first[:value]).to eq('1.5')
        end
      end
    end

    context 'with other projects' do
      let(:from) { 4.days.ago }

      before do
        create(:closed_issue, created_at: 1.day.ago, closed_at: Time.zone.now, project: create(:project, namespace: create(:group)))
        create(:closed_issue, created_at: 2.days.ago, closed_at: Time.zone.now,  project: project)
        create(:closed_issue, created_at: 3.days.ago, closed_at: Time.zone.now,  project: project_2)
      end

      it 'does not find the lead time of issues from them' do
        # Median of  2, 3, not including first issue
        expect(subject.first[:value]).to eq('2.5')
      end
    end
  end

  describe '#cycle_time' do
    let(:created_at) { 6.days.ago }

    context 'with `from` date' do
      let(:from) { 7.days.ago }

      before do
        issue_1 = create(:closed_issue, project: project, closed_at: Time.zone.now, created_at: created_at)
        issue_2 = create(:closed_issue, project: project, closed_at: Time.zone.now, created_at: created_at)
        issue_3 = create(:closed_issue, project: project_2, closed_at: Time.zone.now, created_at: created_at)

        issue_1.metrics.update!(first_mentioned_in_commit_at: 1.day.ago)
        issue_2.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
        issue_3.metrics.update!(first_mentioned_in_commit_at: 4.days.ago)
      end

      it 'finds the cycle time of issues created after it' do
        expect(subject.second[:value]).to eq('2.0')
      end

      context 'with subgroups' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project_3) { create(:project, namespace: subgroup) }

        before do
          issue_4 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: project_3)
          issue_5 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: project_3)

          issue_4.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
          issue_5.metrics.update!(first_mentioned_in_commit_at: 5.days.ago)
        end

        it 'finds the cycle time of issues from them' do
          expect(subject.second[:value]).to eq('3.0')
        end
      end

      context 'with projects specified in options' do
        before do
          issue_4 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: create(:project, namespace: group))
          issue_4.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
        end

        subject { described_class.new(group, options: { from: from, current_user: user, projects: [project.id, project_2.id] }).data }

        it 'finds the cycle time of issues from those projects' do
          # Median of 1, 2, 4, not including new issue
          expect(subject.second[:value]).to eq('2.0')
        end
      end

      context 'when `from` and `to` parameters are provided' do
        let(:from) { 5.days.ago }
        let(:to) { 2.days.ago }
        let(:created_at) { from }

        it 'finds the cycle time of issues created between `from` and `to`' do
          # Median of 1, 2, 4
          expect(subject.second[:value]).to eq('2.0')
        end
      end
    end

    context 'with other projects' do
      let(:from) { 4.days.ago }
      let(:created_at) { from }

      before do
        issue_1 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now, project: create(:project, namespace: create(:group)))
        issue_2 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now,  project: project)
        issue_3 = create(:closed_issue, created_at: created_at, closed_at: Time.zone.now,  project: project_2)

        issue_1.metrics.update!(first_mentioned_in_commit_at: 1.day.ago)
        issue_2.metrics.update!(first_mentioned_in_commit_at: 2.days.ago)
        issue_3.metrics.update!(first_mentioned_in_commit_at: 3.days.ago)
      end

      it 'does not find the cycle time of issues from them' do
        # Median of  2, 3, not including first issue
        expect(subject.second[:value]).to eq('2.5')
      end
    end
  end
end
