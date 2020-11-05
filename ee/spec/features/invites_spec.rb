# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group or Project invitations' do
  let(:group) { create(:group, name: 'Owned') }
  let(:project) { create(:project, :repository, namespace: group) }
  let(:group_invite) { create(:group_member, :invited, group: group) }
  let(:new_user) { build_stubbed(:user, email: group_invite.invite_email) }
  let(:dev_env_or_com) { true }

  before do
    allow(::Gitlab).to receive(:dev_env_or_com?).and_return(dev_env_or_com)

    visit invite_path(group_invite.raw_invite_token)
    click_link 'Register now'
  end

  def fill_in_sign_up_form(user)
    fill_in 'new_user_first_name', with: user.first_name
    fill_in 'new_user_last_name', with: user.last_name
    fill_in 'new_user_username', with: user.username
    fill_in 'new_user_email', with: user.email
    fill_in 'new_user_password', with: user.password
    click_button 'Register'
  end

  context 'when on .com' do
    context 'without setup question' do
      it 'bypasses the setup_for_company question' do
        fill_in_sign_up_form(new_user)

        expect(find('input[name="user[setup_for_company]"]', visible: :hidden).value).to eq 'true'
        expect(page).not_to have_content('My company or team')
      end
    end

    context 'with setup question' do
      let(:new_user) {  build_stubbed(:user, email: 'bogus@me.com') }

      it 'has the setup question' do
        fill_in_sign_up_form(new_user)

        expect(page).to have_content('My company or team')
      end
    end
  end

  context 'when not on .com' do
    let(:dev_env_or_com) { false }

    it 'bypasses the setup_for_company question' do
      fill_in_sign_up_form(new_user)

      expect(page).not_to have_content('My company or team')
    end
  end
end
