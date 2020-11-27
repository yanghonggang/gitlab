# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Nodes', :js, :geo do
  let!(:geo_node) { create(:geo_node) }

  def expect_fields(node_fields)
    node_fields.each do |field|
      expect(page).to have_field(field)
    end
  end

  def expect_no_fields(node_fields)
    node_fields.each do |field|
      expect(page).not_to have_field(field)
    end
  end

  def expect_breadcrumb(text)
    breadcrumbs = page.all(:css, '.breadcrumbs-list>li')
    expect(breadcrumbs.length).to eq(3)
    expect(breadcrumbs[0].text).to eq('Admin Area')
    expect(breadcrumbs[1].text).to eq('Geo Nodes')
    expect(breadcrumbs[2].text).to eq(text)
  end

  before do
    allow(Gitlab::Geo).to receive(:license_allows?).and_return(true)
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  describe 'index' do
    it 'show all public Geo Nodes and create new node link' do
      visit admin_geo_nodes_path
      wait_for_requests

      expect(page).to have_link('New node', href: new_admin_geo_node_path)
      page.within(find('.card', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end

    context 'hashed storage warnings' do
      let(:enable_warning) { 'Please enable and migrate to hashed storage' }
      let(:migrate_warning) { 'Please migrate all existing projects' }
      let(:user_callout_close_button) { '.user-callout .js-close' }

      context 'without hashed storage enabled' do
        before do
          stub_application_setting(hashed_storage_enabled: false)
        end

        it 'shows a dismissable warning to enable hashed storage' do
          visit admin_geo_nodes_path

          expect(page).to have_content enable_warning
          expect(page).to have_selector user_callout_close_button
        end
      end

      context 'with hashed storage enabled' do
        before do
          stub_application_setting(hashed_storage_enabled: true)
        end

        context 'with all projects in hashed storage' do
          let!(:project) { create(:project) }

          it 'does not show any hashed storage warning' do
            visit admin_geo_nodes_path

            expect(page).not_to have_content enable_warning
            expect(page).not_to have_content migrate_warning
            expect(page).not_to have_selector user_callout_close_button
          end
        end

        context 'with at least one project in legacy storage' do
          let!(:project) { create(:project, :legacy_storage) }

          it 'shows a dismissable warning to migrate to hashed storage' do
            visit admin_geo_nodes_path

            expect(page).to have_content migrate_warning
            expect(page).to have_selector user_callout_close_button
          end
        end
      end
    end
  end

  describe 'node form fields' do
    primary_only_fields = %w(node-internal-url-field node-reverification-interval-field)
    secondary_only_fields = %w(node-selective-synchronization-field node-repository-capacity-field node-file-capacity-field node-object-storage-field)

    it 'when primary renders only primary fields' do
      geo_node.update!(primary: true)
      visit edit_admin_geo_node_path(geo_node)

      expect_fields(primary_only_fields)
      expect_no_fields(secondary_only_fields)
    end

    it 'when secondary renders only secondary fields' do
      geo_node.update!(primary: false)
      visit edit_admin_geo_node_path(geo_node)

      expect_no_fields(primary_only_fields)
      expect_fields(secondary_only_fields)
    end
  end

  describe 'create a new Geo Node' do
    let(:new_ssh_key) { attributes_for(:key)[:key] }

    before do
      visit new_admin_geo_node_path
    end

    it 'creates a new Geo Node' do
      fill_in 'node-name-field', with: 'a node name'
      fill_in 'node-url-field', with: 'https://test.gitlab.com'
      click_button 'Save'

      wait_for_requests
      expect(current_path).to eq admin_geo_nodes_path

      page.within(find('.card', match: :first)) do
        expect(page).to have_content(geo_node.url)
      end
    end

    it 'includes Geo Nodes in breadcrumbs' do
      expect_breadcrumb('Add New Node')
    end
  end

  describe 'update an existing Geo Node' do
    before do
      geo_node.update!(primary: true)

      visit edit_admin_geo_node_path(geo_node)
    end

    it 'updates an existing Geo Node' do
      fill_in 'node-url-field', with: 'http://newsite.com'
      fill_in 'node-internal-url-field', with: 'http://internal-url.com'
      click_button 'Save changes'

      wait_for_requests
      expect(current_path).to eq admin_geo_nodes_path

      page.within(find('.card', match: :first)) do
        expect(page).to have_content('http://newsite.com')
        expect(page).to have_content('Primary')

        click_button 'Other information'

        page.within(find('.other-section')) do
          expect(page).to have_content('http://internal-url.com')
        end
      end
    end

    it 'includes Geo Nodes in breadcrumbs' do
      expect_breadcrumb('Edit Geo Node')
    end
  end

  describe 'remove an existing Geo Node' do
    before do
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'removes an existing Geo Node' do
      page.within(find('[data-testid="nodeActions"]', match: :first)) do
        page.click_button('Remove')
      end
      page.within('.modal') do
        page.click_button('Remove')
      end

      expect(current_path).to eq admin_geo_nodes_path
      wait_for_requests
      expect(page).not_to have_css('.card')
    end
  end

  describe 'with no Geo Nodes' do
    before do
      geo_node.delete
      visit admin_geo_nodes_path
      wait_for_requests
    end

    it 'hides the New Node button' do
      expect(page).not_to have_link('New node', href: new_admin_geo_node_path)
    end

    it 'shows Discover GitLab Geo' do
      page.within(find('h4')) do
        expect(page).to have_content('Discover GitLab Geo')
      end
    end
  end

  describe 'Geo node form routes' do
    routes = []

    before do
      routes = [{ path: new_admin_geo_node_path, slug: '/new' }, { path: edit_admin_geo_node_path(geo_node), slug: '/edit' }]
    end

    routes.each do |route|
      it "#{route.slug} renders the geo form" do
        visit route.path

        expect(page).to have_css(".geo-node-form-container")
        expect(page).not_to have_css(".js-geo-node-form")
      end
    end
  end
end
