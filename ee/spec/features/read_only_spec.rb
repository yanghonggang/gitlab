# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Geo read-only message', :geo do
  include ::EE::GeoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  before do
    sign_in(user)
  end

  context 'when on a Geo secondary' do
    before do
      stub_current_geo_node(secondary)
    end

    it_behaves_like 'Read-only instance', /You are on a secondary, read\-only Geo node\. If you want to make changes, you must visit the primary site.*Go to the primary site/
  end
end
