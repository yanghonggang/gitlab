# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastScannerProfilePolicy do
  it_behaves_like 'a dast on-demand scan policy' do
    let_it_be(:record) { create(:dast_scanner_profile, project: project) }
  end
end
