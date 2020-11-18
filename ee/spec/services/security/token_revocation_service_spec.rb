# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::TokenRevocationService, '#execute' do
  let_it_be(:revocation_token_types_url) { 'https://myhost.com/api/v1/token_types' }
  let_it_be(:token_revocation_url) { 'https://myhost.com/api/v1/revoke' }

  let_it_be(:revocable_keys) do
    [{
      'type': 'aws_key_id',
      'token': 'AKIASOMEAWSACCESSKEY',
      'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     },
     {
        'type': 'aws_secret',
        'token': 'some_aws_secret_key_some_aws_secret_key_',
        'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     },
     {
        'type': 'aws_secret',
        'token': 'another_aws_secret_key_another_secret_key',
        'location': 'https://mywebsite.com/some-repo/blob/abcdefghijklmnop/compromisedfile.java'
     }]
  end

  let_it_be(:revocable_token_types) do
    { 'types': %w(aws_key_id aws_secret gcp_key_id gcp_secret) }
  end

  subject { described_class.new(revocable_keys: revocable_keys).execute }

  before do
    stub_application_setting(secret_detection_revocation_token_types_url: revocation_token_types_url)
    stub_application_setting(secret_detection_token_revocation_token: 'token1')
    stub_application_setting(secret_detection_token_revocation_url: token_revocation_url)
  end

  context 'when revocation token API returns a response with failure' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_revoke_token_api_with_failure
      stub_revocation_token_types_api_with_success
    end

    it 'returns error' do
      expect(subject[:status]).to be(:error)
      expect(subject[:message]).to eql('Failed to revoke tokens')
    end
  end

  context 'when revocation token API returns invalid token types' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_invalid_token_types_api_with_success
    end

    specify { expect(subject).to eql({ message: 'No token type is available', status: :error }) }
  end

  context 'when revocation service is disabled' do
    specify { expect(subject).to eql({ message: 'Token revocation is disabled', status: :error }) }
  end

  context 'when revocation service is enabled' do
    before do
      stub_application_setting(secret_detection_token_revocation_enabled: true)
      stub_revoke_token_api_with_success
    end

    context 'with a list of valid token types' do
      before do
        stub_revocation_token_types_api_with_success
      end

      context 'when there is a list of tokens to be revoked' do
        specify { expect(subject[:status]).to be(:success) }
      end

      context 'when token_revocation_url is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:token_revocation_url) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation tokens data', status: :error }) }
      end

      context 'when token_types_url is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:token_types_url) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation tokens data', status: :error }) }
      end

      context 'when revocation_api_token is missing' do
        before do
          allow_next_instance_of(described_class) do |token_revocation_service|
            allow(token_revocation_service).to receive(:revocation_api_token) { nil }
          end
        end

        specify { expect(subject).to eql({ message: 'Missing revocation tokens data', status: :error }) }
      end

      context 'when there is no token to be revoked' do
        let_it_be(:revocable_token_types) do
          { 'types': %w() }
        end

        specify { expect(subject).to eql({ message: 'No token type is available', status: :error }) }
      end
    end

    context 'when revocation token types API returns an unsuccessful response' do
      before do
        stub_revocation_token_types_api_with_failure
      end

      specify { expect(subject).to eql({ message: 'Failed to get revocation token types', status: :error }) }
    end
  end

  def stub_revoke_token_api_with_success
    stub_request(:post, token_revocation_url)
      .with(body: revocable_keys.to_json)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revoke_token_api_with_failure
    stub_request(:post, token_revocation_url)
      .with(body: revocable_keys.to_json)
      .to_return(
        status: 400,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revocation_token_types_api_with_success
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: revocable_token_types.to_json
      )
  end

  def stub_invalid_token_types_api_with_success
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end

  def stub_revocation_token_types_api_with_failure
    stub_request(:get, revocation_token_types_url)
      .to_return(
        status: 400,
        headers: { 'Content-Type' => 'application/json' },
        body: {}.to_json
      )
  end
end
