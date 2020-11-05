# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ConfirmService do
  include AccessMatchersGeneric

  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }
  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:vulnerability) { create(:vulnerability, :with_findings, project: project) }
  let(:service) { described_class.new(user, vulnerability) }

  subject(:confirm_vulnerability) { service.execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'calls vulnerability statistics utility services in order'
    it_behaves_like 'removes dismissal feedback from associated findings'

    it 'confirms a vulnerability' do
      freeze_time do
        confirm_vulnerability

        expect(vulnerability.reload).to(
          have_attributes(state: 'confirmed', confirmed_by: user, confirmed_at: be_like_time(Time.current)))
      end
    end

    it 'creates note' do
      expect(SystemNoteService).to receive(:change_vulnerability_state).with(vulnerability, user)

      confirm_vulnerability
    end

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an "access denied" error' do
        expect { confirm_vulnerability }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  describe 'permissions' do
    it { expect { confirm_vulnerability }.to be_allowed_for(:admin) }
    it { expect { confirm_vulnerability }.to be_allowed_for(:owner).of(project) }
    it { expect { confirm_vulnerability }.to be_allowed_for(:maintainer).of(project) }
    it { expect { confirm_vulnerability }.to be_allowed_for(:developer).of(project) }

    it { expect { confirm_vulnerability }.to be_denied_for(:auditor) }
    it { expect { confirm_vulnerability }.to be_denied_for(:reporter).of(project) }
    it { expect { confirm_vulnerability }.to be_denied_for(:guest).of(project) }
    it { expect { confirm_vulnerability }.to be_denied_for(:anonymous) }
  end
end
