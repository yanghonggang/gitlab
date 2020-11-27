# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admin views license" do
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    allow_any_instance_of(Gitlab::ExpiringSubscriptionMessage).to receive(:grace_period_effective_from).and_return(Date.today - 45.days)
  end

  context "when license is valid" do
    before do
      visit(admin_license_path)
    end

    it "shows license" do
      expect(page).to have_content("Your license is valid")

      page.within(".license-panel") do
        expect(page).to have_content("Unlimited")
      end
    end
  end

  context "when license is regular" do
    let_it_be(:license) { create(:license) }

    before do
      visit(admin_license_path)
    end

    context "when license expired" do
      let_it_be(:license) { build(:license, data: build(:gitlab_license, expires_at: Date.yesterday).export).save!(validate: false) }

      it { expect(page).to have_content("Your subscription expired!") }

      context "when license blocks changes" do
        let_it_be(:license) { build(:license, data: build(:gitlab_license, expires_at: Date.yesterday, block_changes_at: Date.today).export).save!(validate: false) }

        it { expect(page).to have_content "You didn't renew your subscription so it was downgraded to the GitLab Core Plan" }
      end
    end

    context "when viewing license history", :aggregate_failures do
      it "shows licensee" do
        license_history = page.find("#license_history")

        License.history.each do |license|
          expect(license_history).to have_content(license.licensee.each_value.first)
        end
      end

      it "highlights the current license with a css class", :aggregate_failures do
        license_history = page.find("#license_history")
        highlighted_license_row = license_history.find("[data-testid='license-current']")

        expect(highlighted_license_row).to have_content(license.licensee[:name])
        expect(highlighted_license_row).to have_content(license.licensee[:email])
        expect(highlighted_license_row).to have_content(license.licensee[:company])
        expect(highlighted_license_row).to have_content(license.plan.capitalize)
        expect(highlighted_license_row).to have_content(I18n.l(license.created_at, format: :with_timezone))
        expect(highlighted_license_row).to have_content(I18n.l(license.starts_at))
        expect(highlighted_license_row).to have_content(I18n.l(license.expires_at))
        expect(highlighted_license_row).to have_content(license.restrictions[:active_user_count])
      end
    end
  end

  context "with limited users" do
    let_it_be(:license) { create(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export) }

    before do
      visit(admin_license_path)
    end

    it "shows panel counts" do
      page.within(".license-panel") do
        expect(page).to have_content("2,000")
      end
    end
  end

  context "when existing licenses only contain a future-dated license" do
    let_it_be(:license) { create(:license, data: create(:gitlab_license, starts_at: Date.current + 1.month).export) }

    before do
      License.where.not(id: license.id).delete_all

      visit(admin_license_path)
    end

    context "when viewing license history" do
      it "shows licensee" do
        license_history = page.find("#license_history")

        expect(license_history).to have_content(license.licensee.each_value.first)
      end

      it "has no highlighted license", :aggregate_failures do
        license_history = page.find("#license_history")

        expect(license_history).not_to have_selector("[data-testid='license-current']")
      end

      it "shows only the future-dated license", :aggregate_failures do
        license_history = page.find("#license_history")
        license_history_row = license_history.find('tbody tr', match: :first)

        expect(license_history).to have_css('tbody tr', count: 1)

        expect(license_history_row).to have_content(license.licensee[:name])
        expect(license_history_row).to have_content(license.licensee[:email])
        expect(license_history_row).to have_content(license.licensee[:company])
        expect(license_history_row).to have_content(license.plan.capitalize)
        expect(license_history_row).to have_content(I18n.l(license.created_at, format: :with_timezone))
        expect(license_history_row).to have_content(I18n.l(license.starts_at))
        expect(license_history_row).to have_content(I18n.l(license.expires_at))
        expect(license_history_row).to have_content(license.restrictions[:active_user_count])
      end
    end
  end
end
