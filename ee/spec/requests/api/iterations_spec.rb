# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Iterations do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: parent_group) }

  let_it_be(:iteration) { create(:iteration, group: group, title: 'search_title') }
  let_it_be(:closed_iteration) { create(:iteration, :closed, group: group) }
  let_it_be(:ancestor_iteration) { create(:iteration, group: parent_group) }

  before_all do
    parent_group.add_guest(user)
  end

  shared_examples 'iterations list' do
    context 'when user does not have access' do
      it 'returns 404' do
        get api(api_path, nil)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user has access' do
      it 'returns a list of iterations' do
        get api(api_path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(3)
        expect(json_response.map { |i| i['id'] }).to contain_exactly(iteration.id, closed_iteration.id, ancestor_iteration.id)
      end

      it 'returns iterations filtered by state' do
        get api(api_path, user), params: { state: 'closed' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(closed_iteration.id)
      end

      it 'returns iterations filtered by title' do
        get api(api_path, user), params: { search: 'search_' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(iteration.id)
      end

      it 'returns 400 when param is invalid' do
        get api(api_path, user), params: { state: 'non-existent-state' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'GET /groups/:id/iterations' do
    let(:api_path) { "/groups/#{group.id}/iterations" }

    it_behaves_like 'iterations list'

    it 'excludes ancestor iterations when include_ancestors is set to false' do
      get api(api_path, user), params: { include_ancestors: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |i| i['id'] }).to contain_exactly(iteration.id, closed_iteration.id)
    end
  end

  describe 'GET /projects/:id/iterations' do
    let_it_be(:project) { create(:project, :private, group: group) }

    let(:api_path) { "/projects/#{project.id}/iterations" }

    it_behaves_like 'iterations list'

    it 'excludes ancestor iterations when include_ancestors is set to false' do
      get api(api_path, user), params: { include_ancestors: false }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.size).to eq(0)
    end
  end
end
