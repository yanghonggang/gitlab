# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteValidation, type: :model do
  subject { create(:dast_site_validation) }

  let_it_be(:another_dast_site_validation) { create(:dast_site_validation) }

  describe 'associations' do
    it { is_expected.to belong_to(:dast_site_token) }
    it { is_expected.to have_many(:dast_sites) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:dast_site_token_id) }
  end

  describe 'before_create' do
    describe '#set_normalized_url_base' do
      subject do
        dast_site_token = create(
          :dast_site_token,
          url: generate(:url) + '/' + SecureRandom.hex + '?' + { param: SecureRandom.hex }.to_query
        )

        create(:dast_site_validation, dast_site_token: dast_site_token)
      end

      it 'normalizes the dast_site_token url' do
        uri = URI(subject.dast_site_token.url)

        expect(subject.url_base).to eq("#{uri.scheme}://#{uri.host}:#{uri.port}")
      end
    end
  end

  describe 'scopes' do
    describe 'by_project_id' do
      it 'includes the correct records' do
        result = described_class.by_project_id(subject.dast_site_token.project_id)

        aggregate_failures do
          expect(result).to include(subject)
          expect(result).not_to include(another_dast_site_validation)
        end
      end
    end

    describe 'by_url_base' do
      let(:more_dast_site_validations) do
        create_list(:dast_site_validation, 5, dast_site_token: subject.dast_site_token).prepend(subject)
      end

      it 'includes the correct records' do
        result = described_class.by_url_base(subject.url_base)

        expect(result).not_to include(another_dast_site_validation)
      end
    end
  end

  describe 'enums' do
    let(:validation_strategies) do
      { text_file: 0, header: 1 }
    end

    it { is_expected.to define_enum_for(:validation_strategy).with_values(validation_strategies) }
  end

  describe '#project' do
    it 'returns project through dast_site_token' do
      expect(subject.project).to eq(subject.dast_site_token.project)
    end
  end

  describe '#validation_url' do
    it 'formats the url correctly' do
      expect(subject.validation_url).to eq("#{subject.url_base}/#{subject.url_path}")
    end
  end

  describe '#start' do
    context 'when state=pending' do
      it 'returns true' do
        expect(subject.start).to eq(true)
      end

      it 'records a timestamp' do
        freeze_time do
          subject.start

          expect(subject.reload.validation_started_at).to eq(Time.now.utc)
        end
      end

      it 'transitions to the correct state' do
        subject.start

        expect(subject.state).to eq('inprogress')
      end
    end

    context 'otherwise' do
      subject { create(:dast_site_validation, state: :failed) }

      it 'returns false' do
        expect(subject.start).to eq(false)
      end
    end
  end

  describe '#retry' do
    context 'when state=failed' do
      subject { create(:dast_site_validation, state: :failed) }

      it 'returns true' do
        expect(subject.retry).to eq(true)
      end

      it 'records a timestamp' do
        freeze_time do
          subject.retry

          expect(subject.reload.validation_last_retried_at).to eq(Time.now.utc)
        end
      end

      it 'transitions to the correct state' do
        subject.retry

        expect(subject.state).to eq('inprogress')
      end
    end

    context 'otherwise' do
      it 'returns false' do
        expect(subject.retry).to eq(false)
      end
    end
  end

  describe '#fail_op' do
    context 'when state=failed' do
      subject { create(:dast_site_validation, state: :failed) }

      it 'returns false' do
        expect(subject.fail_op).to eq(false)
      end
    end

    context 'otherwise' do
      it 'returns true' do
        expect(subject.fail_op).to eq(true)
      end

      it 'records a timestamp' do
        freeze_time do
          subject.fail_op

          expect(subject.reload.validation_failed_at).to eq(Time.now.utc)
        end
      end

      it 'transitions to the correct state' do
        subject.fail_op

        expect(subject.state).to eq('failed')
      end
    end
  end

  describe '#pass' do
    context 'when state=inprogress' do
      subject { create(:dast_site_validation, state: :inprogress) }

      it 'returns true' do
        expect(subject.pass).to eq(true)
      end

      it 'records a timestamp' do
        freeze_time do
          subject.pass

          expect(subject.reload.validation_passed_at).to eq(Time.now.utc)
        end
      end

      it 'transitions to the correct state' do
        subject.pass

        expect(subject.state).to eq('passed')
      end
    end

    context 'otherwise' do
      it 'returns false' do
        expect(subject.pass).to eq(false)
      end
    end
  end
end
