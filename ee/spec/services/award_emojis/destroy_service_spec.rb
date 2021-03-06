# frozen_string_literal: true

require 'spec_helper'

describe AwardEmojis::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:awardable) { create(:note_on_issue, project: project) }
  let(:name) { 'thumbsup' }

  subject(:service) { described_class.new(awardable, name, user) }

  describe '#execute' do
    describe 'publish to status page' do
      let(:execute) { service.execute }
      let(:issue_id) { awardable.noteable_id }

      before do
        create(:award_emoji, user: user, name: name, awardable: awardable)
      end

      context 'with recognized emoji' do
        let(:name) { StatusPage::AWARD_EMOJI }

        include_examples 'trigger status page publish'
      end

      context 'with unrecognized emoji' do
        let(:name) { 'x' }

        include_examples 'no trigger status page publish'
      end
    end
  end
end
