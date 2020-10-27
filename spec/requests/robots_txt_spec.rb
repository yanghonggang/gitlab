# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Robots.txt Requests', :aggregate_failures do
  before do
    Gitlab::Testing::RobotsBlockerMiddleware.block_requests!
  end

  after do
    Gitlab::Testing::RobotsBlockerMiddleware.allow_requests!
  end

  it 'allows the requests' do
    requests = [
      '/users/sign_in',
      '/namespace/subnamespace/design.gitlab.com'
    ]

    requests.each do |request|
      get request

      expect(response).not_to have_gitlab_http_status(:service_unavailable), "#{request} must be allowed"
    end
  end

  it 'blocks the requests' do
    requests = [
      '/autocomplete/users',
      '/search',
      '/admin',
      '/profile',
      '/dashboard',
      '/users',
      '/users/foo',
      '/help',
      '/s/',
      '/-/profile',
      '/foo/bar/new',
      '/foo/bar/edit',
      '/foo/bar/raw',
      '/groups/foo/analytics',
      '/groups/foo/contribution_analytics',
      '/groups/foo/group_members',
      '/foo/bar/project.git',
      '/foo/bar/archive/foo',
      '/foo/bar/repository/archive',
      '/foo/bar/activity',
      '/foo/bar/blame',
      '/foo/bar/commits',
      '/foo/bar/commit',
      '/foo/bar/compare',
      '/foo/bar/network',
      '/foo/bar/graphs',
      '/foo/bar/merge_requests/1.patch',
      '/foo/bar/merge_requests/1.diff',
      '/foo/bar/merge_requests/1/diffs',
      '/foo/bar/deploy_keys',
      '/foo/bar/hooks',
      '/foo/bar/services',
      '/foo/bar/protected_branches',
      '/foo/bar/uploads/foo',
      '/foo/bar/project_members',
      '/foo/bar/settings',
      '/namespace/subnamespace/design.gitlab.com/settings'
    ]

    requests.each do |request|
      get request

      expect(response).to have_gitlab_http_status(:service_unavailable), "#{request} must be disallowed"
    end
  end
end
