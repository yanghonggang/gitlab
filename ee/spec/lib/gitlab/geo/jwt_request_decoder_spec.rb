# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::JwtRequestDecoder do
  include EE::GeoHelpers

  let!(:primary_node) { FactoryBot.create(:geo_node, :primary) }
  let(:data) { { input: 123, other_input: 'string value' } }
  let(:request) { Gitlab::Geo::TransferRequest.new(data) }

  subject { described_class.new(request.headers['Authorization']) }

  before do
    stub_current_geo_node(primary_node)
  end

  describe '#decode' do
    it 'decodes correct data' do
      expect(subject.decode).to eq(data)
    end

    it 'fails to decode when node is disabled' do
      primary_node.update_attribute(:enabled, false)

      expect(subject.decode).to be_nil
    end

    it 'decodes when node is disabled if `include_disabled!` is called first' do
      primary_node.update_attribute(:enabled, false)

      subject.include_disabled!

      expect(subject.decode).to eq(data)
    end

    it 'fails to decode with wrong key' do
      data = request.headers['Authorization']

      primary_node.secret_access_key = ''
      primary_node.save!
      expect(described_class.new(data).decode).to be_nil
    end

    it 'successfully decodes when clocks are off by IAT leeway' do
      subject

      travel_to(30.seconds.ago) { expect(subject.decode).to eq(data) }
    end

    it 'raises InvalidSignatureTimeError after expiring' do
      subject

      Timecop.travel(2.minutes) { expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
    end

    it 'raises InvalidSignatureTimeError to decode when clocks are not in sync' do
      subject

      travel_to(2.minutes.ago) { expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidSignatureTimeError) }
    end

    it 'raises invalid decryption key error' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:decode_auth_header).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)
      end

      expect { subject.decode }.to raise_error(Gitlab::Geo::InvalidDecryptionKeyError)
    end
  end

  describe '#valid_attributes?' do
    it 'returns true when all given attributes and decoded data are all the same' do
      expect(subject.valid_attributes?(input: 123, other_input: 'string value')).to be_truthy
    end

    it 'returns true when given attributes is a slice of decoded data' do
      expect(subject.valid_attributes?(input: 123)).to be_truthy
    end

    it 'returns false when one given data doesnt match its corresponding decoded one' do
      expect(subject.valid_attributes?(input: 123, other_input: 'wrong value')).to be_falsey
    end
  end
end
