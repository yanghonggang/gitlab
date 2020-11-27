# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'admin Geo Sidebar', :js, :geo do
  include ::EE::GeoHelpers
  include StubENV

  let_it_be(:admin) { create(:admin) }

  before do
    stub_licensed_features(geo: true)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  shared_examples 'active sidebar link' do |link_name|
    before do
      visit path
      wait_for_requests
    end

    it 'has active class' do
      sidebar_link = page.find("a[title=\"#{link_name}\"]").find(:xpath, '..')
      expect(sidebar_link[:class]).to include('active')
    end
  end

  describe 'visiting geo nodes' do
    it_behaves_like 'active sidebar link', 'Nodes' do
      let(:path) { admin_geo_nodes_path }
    end
  end

  describe 'visiting geo settings' do
    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    end

    it_behaves_like 'active sidebar link', 'Settings' do
      let(:path) { admin_geo_settings_path }
    end
  end

  context 'on secondary' do
    before do
      stub_secondary_node
    end

    describe 'visiting geo projects' do
      it_behaves_like 'active sidebar link', 'Replication' do
        let(:path) { admin_geo_projects_path }
      end
    end

    describe 'visiting geo designs' do
      it_behaves_like 'active sidebar link', 'Replication' do
        let(:path) { admin_geo_designs_path }
      end
    end

    describe 'visiting geo uploads' do
      it_behaves_like 'active sidebar link', 'Replication' do
        let(:path) { admin_geo_uploads_path }
      end
    end

    describe 'visiting geo replicables' do
      Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
        it_behaves_like 'active sidebar link', 'Replication' do
          let(:path) { admin_geo_replicables_path(replicable_name_plural: replicator_class.replicable_name_plural) }
        end
      end
    end
  end
end
