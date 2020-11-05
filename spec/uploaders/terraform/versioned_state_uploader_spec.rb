# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::VersionedStateUploader do
  subject { model.file }

  let(:model) { create(:terraform_state_version, :with_file) }

  before do
    stub_terraform_state_object_storage
  end

  describe '#filename' do
    it 'contains the UUID of the terraform state record' do
      expect(subject.filename).to eq("#{model.version}.tfstate")
    end
  end

  describe '#store_dir' do
    it 'hashes the project ID and UUID' do
      expect(Gitlab::HashedPath).to receive(:new)
        .with(model.uuid, root_hash: model.project_id)
        .and_return(:store_dir)

      expect(subject.store_dir).to eq(:store_dir)
    end
  end
end
