# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ErrorExtensions'] do
  specify { expect(described_class.graphql_name).to eq('ErrorExtensions') }

  it 'has the expected fields' do
    expected_fields = %w[
      code
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
