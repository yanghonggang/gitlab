# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicPolicy do
  include ExternalAuthorizationServiceHelpers

  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  subject { described_class.new(user, epic) }

  shared_examples 'can comment on epics' do
    it { is_expected.to be_allowed(:create_note, :award_emoji) }
  end

  shared_examples 'cannot comment on epics' do
    it { is_expected.to be_disallowed(:create_note, :award_emoji) }
  end

  shared_examples 'can edit epic comments' do
    it { is_expected.to be_allowed(:admin_note) }
  end

  shared_examples 'cannot edit epic comments' do
    it { is_expected.to be_disallowed(:admin_note) }
  end

  shared_examples 'can only read epics' do
    it do
      is_expected.to be_allowed(:read_epic, :read_epic_iid, :read_note, :create_todo)
      is_expected.to be_disallowed(:update_epic, :destroy_epic, :admin_epic, :create_epic)
    end
  end

  shared_examples 'can manage epics' do
    it { is_expected.to be_allowed(:read_epic, :read_epic_iid, :read_note, :update_epic, :admin_epic, :create_epic, :create_todo) }
  end

  shared_examples 'all epic permissions disabled' do
    it { is_expected.to be_disallowed(:read_epic, :read_epic_iid, :update_epic, :destroy_epic, :admin_epic, :create_epic, :create_note, :award_emoji, :read_note, :create_todo) }
  end

  shared_examples 'all reporter epic permissions enabled' do
    it { is_expected.to be_allowed(:read_epic, :read_epic_iid, :update_epic, :admin_epic, :create_epic, :create_note, :award_emoji, :read_note, :create_todo) }
  end

  shared_examples 'group member permissions' do
    context 'guest group member' do
      before do
        group.add_guest(user)
      end

      it_behaves_like 'can only read epics'
      it_behaves_like 'can comment on epics'
      it_behaves_like 'cannot edit epic comments'
    end

    context 'reporter group member' do
      before do
        group.add_reporter(user)
      end

      it_behaves_like 'can manage epics'
      it_behaves_like 'can comment on epics'
      it_behaves_like 'cannot edit epic comments'

      it 'cannot destroy epics' do
        is_expected.to be_disallowed(:destroy_epic)
      end
    end

    context 'group maintainer' do
      before do
        group.add_maintainer(user)
      end

      it_behaves_like 'can manage epics'
      it_behaves_like 'can comment on epics'
      it_behaves_like 'can edit epic comments'

      it 'cannot destroy epics' do
        is_expected.to be_disallowed(:destroy_epic)
      end
    end

    context 'group owner' do
      before do
        group.add_owner(user)
      end

      it_behaves_like 'can manage epics'
      it_behaves_like 'can comment on epics'
      it_behaves_like 'can edit epic comments'

      it 'can destroy epics' do
        is_expected.to be_allowed(:destroy_epic)
      end
    end
  end

  context 'when epics feature is disabled' do
    let(:group) { create(:group, :public) }

    before do
      group.add_owner(user)
    end

    it_behaves_like 'all epic permissions disabled'
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when an epic is in a private group' do
      let(:group) { create(:group, :private) }

      context 'anonymous user' do
        let(:user) { nil }

        it_behaves_like 'all epic permissions disabled'
      end

      context 'user who is not a group member' do
        it_behaves_like 'all epic permissions disabled'
      end

      it_behaves_like 'group member permissions'
    end

    context 'when an epic is in an internal group' do
      let(:group) { create(:group, :internal) }

      context 'anonymous user' do
        let(:user) { nil }

        it_behaves_like 'all epic permissions disabled'
      end

      context 'user who is not a group member' do
        it_behaves_like 'can only read epics'
        it_behaves_like 'can comment on epics'
      end

      it_behaves_like 'group member permissions'
    end

    context 'when an epic is in a public group' do
      let(:group) { create(:group, :public) }

      context 'anonymous user' do
        let(:user) { nil }

        it { is_expected.to be_allowed(:read_epic, :read_epic_iid, :read_note) }
        it { is_expected.to be_disallowed(:create_todo) }
        it_behaves_like 'cannot comment on epics'
      end

      context 'user who is not a group member' do
        it_behaves_like 'can only read epics'
        it_behaves_like 'can comment on epics'
      end

      it_behaves_like 'group member permissions'
    end

    context 'when external authorization is enabled' do
      let(:group) { create(:group) }

      before do
        enable_external_authorization_service_check
        group.add_owner(user)
      end

      it 'does not call external authorization service' do
        expect(::Gitlab::ExternalAuthorization).not_to receive(:access_allowed?)

        subject
      end

      it_behaves_like 'all epic permissions disabled'
    end

    context 'when epic is confidential' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic) { create(:epic, group: group, confidential: true) }

      context 'when user is not reporter' do
        before do
          group.add_guest(user)
        end

        it_behaves_like 'all epic permissions disabled'
      end

      context 'when user is reporter' do
        before do
          group.add_reporter(user)
        end

        it_behaves_like 'all reporter epic permissions enabled'
      end

      context 'when user is developer' do
        before do
          group.add_developer(user)
        end

        it_behaves_like 'all reporter epic permissions enabled'
      end

      context 'when user is maintainer' do
        before do
          group.add_maintainer(user)
        end

        it_behaves_like 'all reporter epic permissions enabled'
      end

      context 'when user is owner' do
        before do
          group.add_owner(user)
        end

        it_behaves_like 'all reporter epic permissions enabled'
      end
    end
  end
end
