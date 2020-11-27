# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ExportCsvService do
  let_it_be(:author) { create(:user, name: "Ru'by McRüb\"Face") }
  let_it_be(:audit_event) do
    create(:project_audit_event,
      entity_id: 678,
      entity_type: 'Project',
      entity_path: 'gitlab-org/awesome-rails',
      target_details: "special package ¯\\_(ツ)_/¯",
      author_id: author.id,
      ip_address: IPAddr.new('192.168.0.1'),
      details: {
        custom_message: "Removed package ,./;'[]\-=",
        target_id: 3, target_type: 'Package'
      },
      created_at: Time.zone.parse('2020-02-20T12:00:00Z'))
  end

  let(:params) do
    {
      entity_type: 'Project',
      entity_id: 678,
      created_before: '2020-03-01',
      created_after: '2020-01-01',
      author_id: author.id
    }
  end

  let(:export_csv_service) { described_class.new(params) }

  subject(:csv) { CSV.parse(export_csv_service.csv_data.to_a.join, headers: true) }

  it 'includes the appropriate headers' do
    expect(csv.headers).to eq([
      'ID', 'Author ID', 'Author Name',
      'Entity ID', 'Entity Type', 'Entity Path',
      'Target ID', 'Target Type', 'Target Details',
      'Action', 'IP Address', 'Created At (UTC)'
    ])
  end

  context 'data verification' do
    specify 'ID' do
      expect(csv[0]['ID']).to eq(audit_event.id.to_s)
    end

    specify 'Author ID' do
      expect(csv[0]['Author ID']).to eq(author.id.to_s)
    end

    specify 'Author Name' do
      expect(csv[0]['Author Name']).to eq("Ru'by McRüb\"Face")
    end

    specify 'Entity ID' do
      expect(csv[0]['Entity ID']).to eq('678')
    end

    specify 'Entity Type' do
      expect(csv[0]['Entity Type']).to eq('Project')
    end

    specify 'Entity Path' do
      expect(csv[0]['Entity Path']).to eq('gitlab-org/awesome-rails')
    end

    specify 'Target ID' do
      expect(csv[0]['Target ID']).to eq('3')
    end

    specify 'Target Type' do
      expect(csv[0]['Target Type']).to eq('Package')
    end

    specify 'Target Details' do
      expect(csv[0]['Target Details']).to eq("special package ¯\\_(ツ)_/¯")
    end

    specify 'Action' do
      expect(csv[0]['Action']).to eq("Removed package ,./;'[]\-=")
    end

    specify 'IP Address' do
      expect(csv[0]['IP Address']).to eq('192.168.0.1')
    end

    specify 'Created At (UTC)' do
      expect(csv[0]['Created At (UTC)']).to eq('2020-02-20T12:00:00Z')
    end
  end
end
