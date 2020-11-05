# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Signup' do
  include TermsHelper

  let(:new_user) { build_stubbed(:user) }

  def fill_in_signup_form
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_password', with: new_user.password
  end

  describe 'username validation', :js do
    before do
      visit new_user_registration_path
    end

    it 'does not show an error border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username contains dots (.)' do
      simulate_input('#new_user_username', 'new.user.username')
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'does not show an error border if the username length is not longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 255
      wait_for_requests

      expect(find('.username')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username already exists' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows a success border if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-success-outline'
    end

    it 'shows an error border if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username is longer than 255 characters' do
      fill_in 'new_user_username', with: 'u' * 256
      wait_for_requests

      expect(page).to have_content("Username is too long (maximum is 255 characters).")
    end

    it 'shows an error message if the username is less than 2 characters' do
      fill_in 'new_user_username', with: 'u'
      wait_for_requests

      expect(page).to have_content("Username is too short (minimum is 2 characters).")
    end

    it 'shows an error message on submit if the username contains special characters' do
      fill_in 'new_user_username', with: 'new$user!username'
      wait_for_requests

      click_button "Register"

      expect(page).to have_content("Please create a username with only alphanumeric characters.")
    end

    it 'shows an error border if the username contains emojis' do
      simulate_input('#new_user_username', 'ehsan😀')

      expect(find('.username')).to have_css '.gl-field-error-outline'
    end

    it 'shows an error message if the username contains emojis' do
      simulate_input('#new_user_username', 'ehsan😀')

      expect(page).to have_content("Invalid input, please avoid emojis")
    end

    it 'shows a pending message if the username availability is being fetched', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/31484' do
      fill_in 'new_user_username', with: 'new-user'

      expect(find('.username > .validation-pending')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is available' do
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(find('.username > .validation-success')).not_to have_css '.hide'
    end

    it 'shows an error message if the username is unavailable' do
      existing_user = create(:user)

      fill_in 'new_user_username', with: existing_user.username
      wait_for_requests

      expect(find('.username > .validation-error')).not_to have_css '.hide'
    end

    it 'shows a success message if the username is corrected and then available' do
      fill_in 'new_user_username', with: 'new-user$'
      wait_for_requests
      fill_in 'new_user_username', with: 'new-user'
      wait_for_requests

      expect(page).to have_content("Username is available.")
    end
  end

  context 'with no errors' do
    context 'when sending confirmation email' do
      before do
        stub_application_setting(send_user_confirmation_email: true)
      end

      context 'when soft email confirmation is not enabled' do
        before do
          stub_feature_flags(soft_email_confirmation: false)
        end

        it 'creates the user account and sends a confirmation email' do
          visit new_user_registration_path

          fill_in_signup_form

          expect { click_button 'Register' }.to change { User.count }.by(1)
          expect(current_path).to eq users_almost_there_path
          expect(page).to have_content('Please check your email to confirm your account')
        end
      end

      context 'when soft email confirmation is enabled' do
        before do
          stub_feature_flags(soft_email_confirmation: true)
        end

        it 'creates the user account and sends a confirmation email' do
          visit new_user_registration_path

          fill_in_signup_form

          expect { click_button 'Register' }.to change { User.count }.by(1)
          expect(current_path).to eq users_sign_up_welcome_path
        end
      end
    end

    context "when not sending confirmation email" do
      before do
        stub_application_setting(send_user_confirmation_email: false)
      end

      it 'creates the user account and goes to dashboard' do
        visit new_user_registration_path

        fill_in_signup_form
        click_button "Register"

        expect(current_path).to eq users_sign_up_welcome_path
      end
    end
  end

  context 'with errors' do
    it "displays the errors" do
      create(:user, email: new_user.email)
      visit new_user_registration_path

      fill_in_signup_form
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page).to have_content("error prohibited this user from being saved")
      expect(page).to have_content("Email has already been taken")
    end

    it 'does not redisplay the password' do
      create(:user, email: new_user.email)
      visit new_user_registration_path

      fill_in_signup_form
      click_button "Register"

      expect(current_path).to eq user_registration_path
      expect(page.body).not_to match(/#{new_user.password}/)
    end
  end

  context 'when terms are enforced' do
    before do
      enforce_terms
    end

    it 'requires the user to check the checkbox' do
      visit new_user_registration_path

      fill_in_signup_form
      click_button 'Register'

      expect(current_path).to eq new_user_session_path
      expect(page).to have_content(/you must accept our terms of service/i)
    end

    it 'asks the user to accept terms before going to the dashboard' do
      visit new_user_registration_path

      fill_in_signup_form
      check :terms_opt_in
      click_button "Register"

      expect(current_path).to eq users_sign_up_welcome_path
    end
  end

  context 'when reCAPTCHA and invisible captcha are enabled' do
    before do
      InvisibleCaptcha.timestamp_enabled = true
      stub_application_setting(recaptcha_enabled: true)
      allow_next_instance_of(RegistrationsController) do |instance|
        allow(instance).to receive(:verify_recaptcha).and_return(true)
      end
    end

    after do
      InvisibleCaptcha.timestamp_enabled = false
    end

    context 'when reCAPTCHA detects malicious behaviour' do
      before do
        allow_next_instance_of(RegistrationsController) do |instance|
          allow(instance).to receive(:verify_recaptcha).and_return(false)
        end
      end

      it 'prevents from signing up' do
        visit new_user_registration_path

        fill_in_signup_form

        expect { click_button 'Register' }.not_to change { User.count }
        expect(page).to have_content('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
      end
    end

    context 'when invisible captcha detects malicious behaviour' do
      it 'prevents from signing up' do
        visit new_user_registration_path

        fill_in_signup_form

        expect { click_button 'Register' }.not_to change { User.count }
        expect(page).to have_content('That was a bit too quick! Please resubmit.')
      end
    end
  end

  it 'redirects to step 2 of the signup process, sets the role and redirects back' do
    visit new_user_registration_path

    fill_in_signup_form
    click_button 'Register'

    visit new_project_path

    expect(page).to have_current_path(users_sign_up_welcome_path)

    select 'Software Developer', from: 'user_role'
    click_button 'Get started!'

    created_user = User.find_by_username(new_user.username)

    expect(created_user.software_developer_role?).to be_truthy
    expect(created_user.setup_for_company).to be_nil
    expect(page).to have_current_path(new_project_path)
  end
end

RSpec.shared_examples 'Signup name validation' do |field, max_length, label|
  before do
    visit new_user_registration_path
  end

  describe "#{field} validation", :js do
    it "does not show an error border if the user's fullname length is not longer than #{max_length} characters" do
      fill_in field, with: 'u' * max_length

      expect(find('.name')).not_to have_css '.gl-field-error-outline'
    end

    it 'shows an error border if the user\'s fullname contains an emoji' do
      simulate_input("##{field}", 'Ehsan 🦋')

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it "shows an error border if the user\'s fullname is longer than #{max_length} characters" do
      fill_in field, with: 'n' * (max_length + 1)

      expect(find('.name')).to have_css '.gl-field-error-outline'
    end

    it "shows an error message if the user\'s #{label} is longer than #{max_length} characters" do
      fill_in field, with: 'n' * (max_length + 1)

      expect(page).to have_content("#{label} is too long (maximum is #{max_length} characters).")
    end

    it 'shows an error message if the username contains emojis' do
      simulate_input("##{field}", 'Ehsan 🦋')

      expect(page).to have_content("Invalid input, please avoid emojis")
    end
  end
end

RSpec.describe 'With original flow' do
  before do
    stub_experiment(signup_flow: false)
    stub_experiment_for_user(signup_flow: false)
  end

  it_behaves_like 'Signup'
  it_behaves_like 'Signup name validation', 'new_user_first_name', 127, 'First name'
  it_behaves_like 'Signup name validation', 'new_user_last_name', 127, 'Last name'
end

RSpec.describe 'With experimental flow' do
  before do
    stub_experiment(signup_flow: true)
    stub_experiment_for_user(signup_flow: true)
  end

  it_behaves_like 'Signup'
  it_behaves_like 'Signup name validation', 'new_user_first_name', 127, 'First name'
  it_behaves_like 'Signup name validation', 'new_user_last_name', 127, 'Last name'

  context 'when terms_opt_in experimental is enabled' do
    include TermsHelper

    before do
      enforce_terms
      stub_experiment(signup_flow: true, terms_opt_in: true)
      stub_experiment_for_user(signup_flow: true, terms_opt_in: true)
    end

    it 'terms are checked by default' do
      new_user = build_stubbed(:user)

      visit new_user_registration_path
      fill_in 'new_user_first_name', with: new_user.first_name
      fill_in 'new_user_last_name', with: new_user.last_name
      fill_in 'new_user_username', with: new_user.username
      fill_in 'new_user_email', with: new_user.email
      fill_in 'new_user_password', with: new_user.password
      click_button 'Register'

      expect(current_path).to eq users_sign_up_welcome_path
    end
  end
end
