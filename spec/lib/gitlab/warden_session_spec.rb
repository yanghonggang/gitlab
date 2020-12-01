# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WardenSession do
  let_it_be(:user) { create :user }
  let_it_be(:another_user) { create :user }
  let_it_be(:warden_session) { { 'warden.user.user.key' => [[user.id], '$eKr3t|<3Y'] } }
  let_it_be(:warden_sessions) { { 'gitlab.warden_sessions' => { user.id => warden_session } } }

  around do |example|
    Gitlab::Session.with_session({}) do
      example.run
    end
  end

  describe '.save' do
    context 'with a warden session' do
      before do
        Gitlab::Session.current.merge!(warden_session)
      end

      it 'should archive warden data' do
        described_class.save

        expect(Gitlab::Session.current).to include warden_sessions
      end
    end

    context 'without a warden session' do
      it 'should archive warden data' do
        described_class.save

        expect(Gitlab::Session.current).to be_empty
      end
    end
  end

  describe '.load' do
    before do
      Gitlab::Session.current.merge!(warden_sessions)
    end

    context 'with an existing user' do
      it 'should load the warden session' do
        described_class.load(user.id)

        expect(Gitlab::Session.current).to include(warden_session)
      end
    end

    context 'with an invalid user' do
      it 'should do nothing' do
        described_class.load(another_user.id)

        expect(Gitlab::Session.current['warden.user.user.key']).to be_nil
      end
    end
  end

  describe '.user_authorized?' do
  end

  describe '.authorized_users' do
  end

  describe '.delete' do
  end
end
