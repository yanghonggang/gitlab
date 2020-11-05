# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['TerraformStateVersion'] do
  it { expect(described_class.graphql_name).to eq('TerraformStateVersion') }
  it { expect(described_class).to require_graphql_authorizations(:read_terraform_state) }

  describe 'fields' do
    let(:fields) { %i[id created_by_user created_at updated_at] }

    it { expect(described_class).to have_graphql_fields(fields) }

    it { expect(described_class.fields['id'].type).to be_non_null }
    it { expect(described_class.fields['createdByUser'].type).not_to be_non_null }
    it { expect(described_class.fields['createdAt'].type).to be_non_null }
    it { expect(described_class.fields['updatedAt'].type).to be_non_null }
  end
end
