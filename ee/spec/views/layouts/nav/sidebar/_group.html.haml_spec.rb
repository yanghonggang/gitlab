# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_group' do
  before do
    assign(:group, group)
  end

  let(:group) { create(:group) }

  describe 'contribution analytics tab' do
    let!(:current_user) { create(:user) }

    before do
      group.add_guest(current_user)

      allow(view).to receive(:current_user).and_return(current_user)
    end

    context 'contribution analytics feature is available' do
      before do
        stub_licensed_features(contribution_analytics: true)
      end

      it 'is visible' do
        render

        expect(rendered).to have_text 'Contribution Analytics'
      end
    end

    context 'contribution analytics feature is not available' do
      before do
        stub_licensed_features(contribution_analytics: false)
      end

      context 'we do not show promotions' do
        before do
          allow(LicenseHelper).to receive(:show_promotions?).and_return(false)
        end

        it 'is not visible' do
          render

          expect(rendered).not_to have_text 'Contribution Analytics'
        end
      end
    end

    context 'no license installed' do
      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(check_namespace_plan: false)

        allow(view).to receive(:can?) { |*args| Ability.allowed?(*args) }
      end

      it 'is visible when there is no valid license but we show promotions' do
        stub_licensed_features(contribution_analytics: false)

        render

        expect(rendered).to have_text 'Contribution Analytics'
      end
    end

    it 'is visible' do
      stub_licensed_features(contribution_analytics: true)

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end

    describe 'group issue boards link' do
      context 'when multiple issue board is disabled' do
        it 'shows link text in singular' do
          render

          expect(rendered).to have_text 'Board'
        end
      end

      context 'when multiple issue board is enabled' do
        before do
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        it 'shows link text in plural' do
          render

          expect(rendered).to have_text 'Boards'
        end
      end
    end
  end

  describe 'security dashboard tab' do
    before do
      stub_licensed_features(security_dashboard: true)
      enable_namespace_license_check!

      create(:gitlab_subscription, hosted_plan: group.plan, namespace: group)
    end

    context 'when security dashboard feature is enabled' do
      let(:group) { create(:group, plan: :gold_plan) }

      it 'is visible' do
        render

        expect(rendered).to have_link 'Security'
      end
    end

    context 'when security dashboard feature is disabled' do
      let(:group) { create(:group, plan: :bronze_plan) }

      it 'is not visible' do
        render

        expect(rendered).not_to have_link 'Security'
      end
    end
  end
end
