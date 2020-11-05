# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders do
  include described_class
  include HttpBasicAuthHelpers

  let(:user) { create(:user) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }

  def set_param(key, value)
    request.update_param(key, value)
  end

  def set_header(key, value)
    env[key] = value
  end

  def set_basic_auth_header(username, password)
    env.merge!(basic_auth_header(username, password))
  end

  shared_examples 'find user from job token' do
    context 'when route is allowed to be authenticated' do
      let(:route_authentication_setting) { { job_token_allowed: true } }

      it "returns an Unauthorized exception for an invalid token" do
        set_token('invalid token')

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      context 'with a running job' do
        before do
          job.update!(status: :running)
        end

        it 'return user if token is valid' do
          set_token(job.token)

          expect(subject).to eq(user)
          expect(@current_authenticated_job).to eq job
        end
      end

      context 'with a job that is not running' do
        before do
          job.update!(status: :failed)
        end

        it 'returns an Unauthorized exception' do
          set_token(job.token)

          expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end
  end

  describe '#find_user_from_bearer_token' do
    let(:job) { create(:ci_build, user: user) }

    subject { find_user_from_bearer_token }

    context 'when the token is passed as an oauth token' do
      def set_token(token)
        env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
      end

      context 'with a job token' do
        it_behaves_like 'find user from job token'
      end

      context 'with oauth token' do
        let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
        let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api').token }

        before do
          set_token(token)
        end

        it { is_expected.to eq user }
      end
    end

    context 'with a personal access token' do
      let(:pat) { create(:personal_access_token, user: user) }
      let(:token) { pat.token }

      before do
        env[described_class::PRIVATE_TOKEN_HEADER] = pat.token
      end

      it { is_expected.to eq user }
    end
  end

  describe '#find_user_from_warden' do
    context 'with CSRF token' do
      before do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'with invalid credentials' do
        it 'returns nil' do
          expect(find_user_from_warden).to be_nil
        end
      end

      context 'with valid credentials' do
        it 'returns the user' do
          set_header('warden', double("warden", authenticate: user))

          expect(find_user_from_warden).to eq user
        end
      end
    end

    context 'without CSRF token' do
      it 'returns nil' do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)
        set_header('warden', double("warden", authenticate: user))

        expect(find_user_from_warden).to be_nil
      end
    end
  end

  describe '#find_user_from_feed_token' do
    context 'when the request format is atom' do
      before do
        set_header('SCRIPT_NAME', 'url.atom')
        set_header('HTTP_ACCEPT', 'application/atom+xml')
      end

      context 'when feed_token param is provided' do
        it 'returns user if valid feed_token' do
          set_param(:feed_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if feed_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid feed_token' do
          set_param(:feed_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when rss_token param is provided' do
        it 'returns user if valid rssd_token' do
          set_param(:rss_token, user.feed_token)

          expect(find_user_from_feed_token(:rss)).to eq user
        end

        it 'returns nil if rss_token is blank' do
          expect(find_user_from_feed_token(:rss)).to be_nil
        end

        it 'returns exception if invalid rss_token' do
          set_param(:rss_token, 'invalid_token')

          expect { find_user_from_feed_token(:rss) }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end

    context 'when the request format is not atom' do
      it 'returns nil' do
        set_header('SCRIPT_NAME', 'json')

        set_param(:feed_token, user.feed_token)

        expect(find_user_from_feed_token(:rss)).to be_nil
      end
    end

    context 'when the request format is empty' do
      it 'the method call does not modify the original value' do
        set_header('SCRIPT_NAME', 'url.atom')

        env.delete('action_dispatch.request.formats')

        find_user_from_feed_token(:rss)

        expect(env['action_dispatch.request.formats']).to be_nil
      end
    end
  end

  describe '#find_user_from_static_object_token' do
    shared_examples 'static object request' do
      before do
        set_header('SCRIPT_NAME', path)
      end

      context 'when token header param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            request.headers['X-Gitlab-Static-Object-Token'] = user.static_object_token

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'returns the user' do
            request.headers['X-Gitlab-Static-Object-Token'] = 'foobar'

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end

      context 'when token query param is present' do
        context 'when token is correct' do
          it 'returns the user' do
            set_param(:token, user.static_object_token)

            expect(find_user_from_static_object_token(format)).to eq(user)
          end
        end

        context 'when token is incorrect' do
          it 'returns the user' do
            set_param(:token, 'foobar')

            expect { find_user_from_static_object_token(format) }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end
      end
    end

    context 'when request format is archive' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/-/archive/master.zip' }
        let_it_be(:format) { :archive }
      end
    end

    context 'when request format is blob' do
      it_behaves_like 'static object request' do
        let_it_be(:path) { 'project/raw/master/README.md' }
        let_it_be(:format) { :blob }
      end
    end

    context 'when request format is not archive nor blob' do
      before do
        set_header('script_name', 'url')
      end

      it 'returns nil' do
        expect(find_user_from_static_object_token(:foo)).to be_nil
      end
    end
  end

  describe '#deploy_token_from_request' do
    let_it_be(:deploy_token) { create(:deploy_token) }
    let_it_be(:route_authentication_setting) { { deploy_token_allowed: true } }

    subject { deploy_token_from_request }

    it { is_expected.to be_nil }

    shared_examples 'an unauthenticated route' do
      context 'when route is not allowed to use deploy_tokens' do
        let(:route_authentication_setting) { { deploy_token_allowed: false } }

        it { is_expected.to be_nil }
      end
    end

    context 'with deploy token headers' do
      before do
        set_header(described_class::DEPLOY_TOKEN_HEADER, deploy_token.token)
      end

      it { is_expected.to eq deploy_token }

      it_behaves_like 'an unauthenticated route'

      context 'with incorrect token' do
        before do
          set_header(described_class::DEPLOY_TOKEN_HEADER, 'invalid_token')
        end

        it { is_expected.to be_nil }
      end
    end

    context 'with oauth headers' do
      before do
        set_header('HTTP_AUTHORIZATION', "Bearer #{deploy_token.token}")
      end

      it { is_expected.to eq deploy_token }

      it_behaves_like 'an unauthenticated route'

      context 'with invalid token' do
        before do
          set_header('HTTP_AUTHORIZATION', "Bearer invalid_token")
        end

        it { is_expected.to be_nil }
      end
    end

    context 'with basic auth headers' do
      before do
        set_basic_auth_header(deploy_token.username, deploy_token.token)
      end

      it { is_expected.to eq deploy_token }

      it_behaves_like 'an unauthenticated route'

      context 'with incorrect token' do
        before do
          set_basic_auth_header(deploy_token.username, 'invalid')
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#find_user_from_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      set_header('SCRIPT_NAME', 'url.atom')
    end

    it 'returns nil if no access_token present' do
      expect(find_user_from_access_token).to be_nil
    end

    context 'when validate_access_token! returns valid' do
      it 'returns user' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)

        expect(find_user_from_access_token).to eq user
      end

      it 'returns exception if token has no user' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)
        allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

        expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'with OAuth headers' do
      it 'returns user' do
        set_header('HTTP_AUTHORIZATION', "Bearer #{personal_access_token.token}")

        expect(find_user_from_access_token).to eq user
      end

      it 'returns exception if invalid personal_access_token' do
        env['HTTP_AUTHORIZATION'] = 'Bearer invalid_20byte_token'

        expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end
  end

  describe '#find_user_from_web_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)
    end

    it 'returns exception if token has no user' do
      allow_any_instance_of(PersonalAccessToken).to receive(:user).and_return(nil)

      expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end

    context 'no feed or API requests' do
      it 'returns nil if the request is not RSS' do
        expect(find_user_from_web_access_token(:rss)).to be_nil
      end

      it 'returns nil if the request is not ICS' do
        expect(find_user_from_web_access_token(:ics)).to be_nil
      end

      it 'returns nil if the request is not API' do
        expect(find_user_from_web_access_token(:api)).to be_nil
      end
    end

    it 'returns the user for RSS requests' do
      set_header('SCRIPT_NAME', 'url.atom')

      expect(find_user_from_web_access_token(:rss)).to eq(user)
    end

    it 'returns the user for ICS requests' do
      set_header('SCRIPT_NAME', 'url.ics')

      expect(find_user_from_web_access_token(:ics)).to eq(user)
    end

    context 'for API requests' do
      it 'returns the user' do
        set_header('SCRIPT_NAME', '/api/endpoint')

        expect(find_user_from_web_access_token(:api)).to eq(user)
      end

      it 'returns nil if URL does not start with /api/' do
        set_header('SCRIPT_NAME', '/relative_root/api/endpoint')

        expect(find_user_from_web_access_token(:api)).to be_nil
      end

      context 'when relative_url_root is set' do
        before do
          stub_config_setting(relative_url_root: '/relative_root')
        end

        it 'returns the user' do
          set_header('SCRIPT_NAME', '/relative_root/api/endpoint')

          expect(find_user_from_web_access_token(:api)).to eq(user)
        end
      end
    end
  end

  describe '#find_personal_access_token' do
    let(:personal_access_token) { create(:personal_access_token, user: user) }

    before do
      set_header('SCRIPT_NAME', 'url.atom')
    end

    context 'passed as header' do
      it 'returns token if valid personal_access_token' do
        set_header(described_class::PRIVATE_TOKEN_HEADER, personal_access_token.token)

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    context 'passed as param' do
      it 'returns token if valid personal_access_token' do
        set_param(described_class::PRIVATE_TOKEN_PARAM, personal_access_token.token)

        expect(find_personal_access_token).to eq personal_access_token
      end
    end

    it 'returns nil if no personal_access_token' do
      expect(find_personal_access_token).to be_nil
    end

    it 'returns exception if invalid personal_access_token' do
      set_header(described_class::PRIVATE_TOKEN_HEADER, 'invalid_token')

      expect { find_personal_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#find_oauth_access_token' do
    let(:application) { Doorkeeper::Application.create!(name: 'MyApp', redirect_uri: 'https://app.com', owner: user) }
    let(:token) { Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: 'api') }

    context 'passed as header' do
      it 'returns token if valid oauth_access_token' do
        set_header('HTTP_AUTHORIZATION', "Bearer #{token.token}")

        expect(find_oauth_access_token.token).to eq token.token
      end
    end

    context 'passed as param' do
      it 'returns user if valid oauth_access_token' do
        set_param(:access_token, token.token)

        expect(find_oauth_access_token.token).to eq token.token
      end
    end

    it 'returns nil if no oauth_access_token' do
      expect(find_oauth_access_token).to be_nil
    end

    it 'returns exception if invalid oauth_access_token' do
      set_header('HTTP_AUTHORIZATION', "Bearer invalid_token")

      expect { find_oauth_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#find_personal_access_token_from_http_basic_auth' do
    def auth_header_with(token)
      set_basic_auth_header('username', token)
    end

    context 'access token is valid' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }
      let(:route_authentication_setting) { { basic_auth_personal_access_token: true } }

      it 'finds the token from basic auth' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to eq personal_access_token
      end
    end

    context 'access token is not valid' do
      let(:route_authentication_setting) { { basic_auth_personal_access_token: true } }

      it 'returns nil' do
        auth_header_with('failing_token')

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end

    context 'route_setting is not set' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }

      it 'returns nil' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end

    context 'route_setting is not correct' do
      let(:personal_access_token) { create(:personal_access_token, user: user) }
      let(:route_authentication_setting) { { basic_auth_personal_access_token: false } }

      it 'returns nil' do
        auth_header_with(personal_access_token.token)

        expect(find_personal_access_token_from_http_basic_auth).to be_nil
      end
    end
  end

  describe '#find_user_from_basic_auth_job' do
    subject { find_user_from_basic_auth_job }

    context 'when the request does not have AUTHORIZATION header' do
      it { is_expected.to be_nil }
    end

    context 'with wrong credentials' do
      it 'returns nil without user and password' do
        set_basic_auth_header(nil, nil)

        is_expected.to be_nil
      end

      it 'returns nil without password' do
        set_basic_auth_header('some-user', nil)

        is_expected.to be_nil
      end

      it 'returns nil without user' do
        set_basic_auth_header(nil, 'password')

        is_expected.to be_nil
      end

      it 'returns nil without CI username' do
        set_basic_auth_header('user', 'password')

        is_expected.to be_nil
      end
    end

    context 'with CI username' do
      let(:username) { ::Gitlab::Auth::CI_JOB_USER }
      let(:user) { create(:user) }
      let(:build) { create(:ci_build, user: user, status: :running) }

      it 'returns nil without password' do
        set_basic_auth_header(username, nil)

        is_expected.to be_nil
      end

      it 'returns user with valid token' do
        set_basic_auth_header(username, build.token)

        is_expected.to eq user
        expect(@current_authenticated_job).to eq build
      end

      it 'raises error with invalid token' do
        set_basic_auth_header(username, 'token')

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      it 'returns exception if the job is not running' do
        set_basic_auth_header(username, build.token)
        build.success!

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end
  end

  describe '#validate_access_token!' do
    subject { validate_access_token! }

    let(:personal_access_token) { create(:personal_access_token, user: user) }

    context 'with a job token' do
      let(:route_authentication_setting) { { job_token_allowed: true } }
      let(:job) { create(:ci_build, user: user, status: :running) }

      before do
        env['HTTP_AUTHORIZATION'] = "Bearer #{job.token}"
        find_user_from_bearer_token
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    it 'returns nil if no access_token present' do
      expect(validate_access_token!).to be_nil
    end

    context 'token is not valid' do
      before do
        allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
      end

      it 'returns Gitlab::Auth::ExpiredError if token expired' do
        personal_access_token.expires_at = 1.day.ago

        expect { validate_access_token! }.to raise_error(Gitlab::Auth::ExpiredError)
      end

      it 'returns Gitlab::Auth::RevokedError if token revoked' do
        personal_access_token.revoke!

        expect { validate_access_token! }.to raise_error(Gitlab::Auth::RevokedError)
      end

      it 'returns Gitlab::Auth::InsufficientScopeError if invalid token scope' do
        expect { validate_access_token!(scopes: [:sudo]) }.to raise_error(Gitlab::Auth::InsufficientScopeError)
      end
    end

    context 'with impersonation token' do
      let(:personal_access_token) { create(:personal_access_token, :impersonation, user: user) }

      context 'when impersonation is disabled' do
        before do
          stub_config_setting(impersonation_enabled: false)
          allow_any_instance_of(described_class).to receive(:access_token).and_return(personal_access_token)
        end

        it 'returns Gitlab::Auth::ImpersonationDisabled' do
          expect { validate_access_token! }.to raise_error(Gitlab::Auth::ImpersonationDisabled)
        end
      end
    end
  end

  describe '#find_user_from_job_token' do
    let(:job) { create(:ci_build, user: user, status: :running) }
    let(:route_authentication_setting) { { job_token_allowed: true } }

    subject { find_user_from_job_token }

    context 'when the job token is in the headers' do
      it 'returns the user if valid job token' do
        set_header(described_class::JOB_TOKEN_HEADER, job.token)

        is_expected.to eq(user)
        expect(@current_authenticated_job).to eq(job)
      end

      it 'returns nil without job token' do
        set_header(described_class::JOB_TOKEN_HEADER, '')

        is_expected.to be_nil
      end

      it 'returns exception if invalid job token' do
        set_header(described_class::JOB_TOKEN_HEADER, 'invalid token')

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      it 'returns exception if the job is not running' do
        set_header(described_class::JOB_TOKEN_HEADER, job.token)
        job.success!

        expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end

      context 'when route is not allowed to be authenticated' do
        let(:route_authentication_setting) { { job_token_allowed: false } }

        it 'sets current_user to nil' do
          set_header(described_class::JOB_TOKEN_HEADER, job.token)

          allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(true)

          is_expected.to be_nil
        end
      end
    end

    context 'when the job token is in the params' do
      shared_examples 'job token params' do |token_key_name|
        before do
          set_param(token_key_name, token)
        end

        context 'with valid job token' do
          let(:token) { job.token }

          it 'returns the user' do
            is_expected.to eq(user)
            expect(@current_authenticated_job).to eq(job)
          end
        end

        context 'with empty job token' do
          let(:token) { '' }

          it 'returns nil' do
            is_expected.to be_nil
          end
        end

        context 'with invalid job token' do
          let(:token) { 'invalid token' }

          it 'returns exception' do
            expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
          end
        end

        context 'when route is not allowed to be authenticated' do
          let(:route_authentication_setting) { { job_token_allowed: false } }
          let(:token) { job.token }

          it 'sets current_user to nil' do
            allow_any_instance_of(Gitlab::UserAccess).to receive(:allowed?).and_return(true)

            is_expected.to be_nil
          end
        end
      end

      it_behaves_like 'job token params', described_class::JOB_TOKEN_PARAM
      it_behaves_like 'job token params', described_class::RUNNER_JOB_TOKEN_PARAM
    end

    context 'when the job token is provided via basic auth' do
      let(:route_authentication_setting) { { job_token_allowed: :basic_auth } }
      let(:username) { ::Gitlab::Auth::CI_JOB_USER }
      let(:token) { job.token }

      before do
        set_basic_auth_header(username, token)
      end

      it { is_expected.to eq(user) }

      context 'credentials are provided but route setting is incorrect' do
        let(:route_authentication_setting) { { job_token_allowed: :unknown } }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#cluster_agent_token_from_authorization_token' do
    let_it_be(:agent_token) { create(:cluster_agent_token) }

    context 'when route_setting is empty' do
      it 'returns nil' do
        expect(cluster_agent_token_from_authorization_token).to be_nil
      end
    end

    context 'when route_setting allows cluster agent token' do
      let(:route_authentication_setting) { { cluster_agent_token_allowed: true } }

      context 'Authorization header is empty' do
        it 'returns nil' do
          expect(cluster_agent_token_from_authorization_token).to be_nil
        end
      end

      context 'Authorization header is incorrect' do
        before do
          request.headers['Authorization'] = 'Bearer ABCD'
        end

        it 'returns nil' do
          expect(cluster_agent_token_from_authorization_token).to be_nil
        end
      end

      context 'Authorization header is malformed' do
        before do
          request.headers['Authorization'] = 'Bearer'
        end

        it 'returns nil' do
          expect(cluster_agent_token_from_authorization_token).to be_nil
        end
      end

      context 'Authorization header matches agent token' do
        before do
          request.headers['Authorization'] = "Bearer #{agent_token.token}"
        end

        it 'returns the agent token' do
          expect(cluster_agent_token_from_authorization_token).to eq(agent_token)
        end
      end
    end
  end

  describe '#find_runner_from_token' do
    let(:runner) { create(:ci_runner) }

    context 'with API requests' do
      before do
        set_header('SCRIPT_NAME', '/api/endpoint')
      end

      it 'returns the runner if token is valid' do
        set_param(:token, runner.token)

        expect(find_runner_from_token).to eq(runner)
      end

      it 'returns nil if token is not present' do
        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if token is blank' do
        set_param(:token, '')

        expect(find_runner_from_token).to be_nil
      end

      it 'returns exception if invalid token' do
        set_param(:token, 'invalid_token')

        expect { find_runner_from_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'without API requests' do
      before do
        set_header('SCRIPT_NAME', 'url.ics')
      end

      it 'returns nil if token is valid' do
        set_param(:token, runner.token)

        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if token is blank' do
        expect(find_runner_from_token).to be_nil
      end

      it 'returns nil if invalid token' do
        set_param(:token, 'invalid_token')

        expect(find_runner_from_token).to be_nil
      end
    end
  end
end
