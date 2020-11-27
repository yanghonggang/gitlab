# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reset namespace pipeline minutes', :js do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  shared_examples 'resetting pipeline minutes' do
    context 'when namespace has namespace statistics' do
      before do
        namespace.create_namespace_statistics(shared_runners_seconds: 100)
      end

      it 'resets pipeline minutes' do
        time = Time.now

        travel_to(time) do
          click_button 'Reset pipeline minutes'
        end

        expect(page).to have_selector('.gl-toast')
        expect(current_path).to include(namespace.path)

        expect(namespace.namespace_statistics.reload.shared_runners_seconds).to eq(0)
        expect(namespace.namespace_statistics.reload.shared_runners_seconds_last_reset).to be_like_time(time)
      end
    end
  end

  shared_examples 'rendering error' do
    context 'when resetting pipeline minutes fails' do
      before do
        allow_any_instance_of(ClearNamespaceSharedRunnersMinutesService).to receive(:execute).and_return(false)
      end

      it 'renders edit page with an error' do
        click_button 'Reset pipeline minutes'

        expect(current_path).to include(namespace.path)
        expect(page).to have_selector('.gl-toast')
      end
    end
  end

  describe 'for user namespace' do
    let(:user) { create(:user) }
    let(:namespace) { user.namespace }

    before do
      visit admin_user_path(user)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_button('Reset pipeline minutes')
    end

    include_examples 'resetting pipeline minutes'
    include_examples 'rendering error'
  end

  describe 'when creating a new group' do
    before do
      visit admin_groups_path
      page.within '#content-body' do
        click_link 'New group'
      end
    end

    it 'does not display reset pipeline minutes callout' do
      expect(page).not_to have_link('Reset pipeline minutes')
    end
  end

  describe 'for group namespace' do
    let(:group) { create(:group) }
    let(:namespace) { group }

    before do
      visit admin_group_path(group)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_button('Reset pipeline minutes')
    end

    include_examples 'resetting pipeline minutes'
    include_examples 'rendering error'
  end
end
