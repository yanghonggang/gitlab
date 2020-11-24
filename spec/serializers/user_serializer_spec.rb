# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserSerializer do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }

  let(:serializer) { described_class.new(options) }

  shared_examples 'user with can_merge' do
    before do
      allow(project).to(
        receive_message_chain(:merge_requests, :find_by_iid!)
        .with(merge_request.iid).and_return(merge_request)
      )

      project.add_maintainer(user1)
    end

    it 'returns a user with can_merge option' do
      serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

      expect(serialized_user1).to include("id" => user1.id, "can_merge" => true)
      expect(serialized_user2).to include("id" => user2.id, "can_merge" => false)
    end
  end

  shared_examples 'user without applicable_approval_rules' do
    it 'returns a user without applicable_approval_rules' do
      serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

      expect(serialized_user1.keys).not_to include("applicable_approval_rules")
      expect(serialized_user2.keys).not_to include("applicable_approval_rules")
    end
  end

  context 'for FOSS' do
    before do
      stub_licensed_features(merge_request_approvers: false)
    end

    context 'with merge_request_iid' do
      let(:options) { { merge_request_iid: merge_request.iid } }

      it_behaves_like 'user with can_merge'

      context 'without approval_rules' do
        it_behaves_like 'user without applicable_approval_rules'
      end

      context 'with approval_rules' do
        let(:options) { super().merge(approval_rules: 'true') }

        before do
          create(:approval_merge_request_rule, name: 'Rule 1', merge_request: merge_request, users: [user1])
        end

        it_behaves_like 'user without applicable_approval_rules'
      end
    end

    context 'without merge_request_iid' do
      let(:options) { {} }

      context 'without approval_rules' do
        it_behaves_like 'user without applicable_approval_rules'
      end

      context 'with approval_rules' do
        let(:options) { super().merge(approval_rules: 'true') }

        let_it_be(:protected_branch) { create(:protected_branch, project: project, name: 'my_branch') }
        let_it_be(:approval_project_rule) do
          create(:approval_project_rule, name: 'Rule 2', project: project, users: [user1], protected_branches: [protected_branch])
        end

        it_behaves_like 'user without applicable_approval_rules'

        context 'with target_branch' do
          let(:options) { super().merge(target_branch: 'my_branch') }

          it_behaves_like 'user without applicable_approval_rules'
        end
      end
    end
  end

  context 'for EE' do
    context 'with merge_request_iid' do
      let(:options) { { merge_request_iid: merge_request.iid } }

      it_behaves_like 'user with can_merge'

      context 'without approval_rules' do
        it_behaves_like 'user without applicable_approval_rules'
      end

      context 'with approval_rules' do
        let(:options) { super().merge(approval_rules: 'true') }

        before do
          create(:approval_merge_request_rule, name: 'Rule 1', merge_request: merge_request, users: [user1])
        end

        it 'returns users with applicable_approval_rules' do
          serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

          expect(serialized_user1).to include(
            "id" => user1.id,
            "applicable_approval_rules" => [
               { "id" => 1, "name" => "Rule 1", "rule_type" => "regular" }
            ]
          )
          expect(serialized_user2).to include("id" => user2.id, "applicable_approval_rules" => [])
        end
      end
    end

    context 'without merge_request_iid' do
      let(:options) { {} }

      context 'without approval_rules' do
        it_behaves_like 'user without applicable_approval_rules'
      end

      context 'with approval_rules' do
        let(:options) { super().merge(approval_rules: 'true') }

        let_it_be(:protected_branch) { create(:protected_branch, project: project, name: 'my_branch') }
        let_it_be(:approval_project_rule) do
          create(:approval_project_rule, name: 'Rule 2', project: project, users: [user1], protected_branches: [protected_branch])
        end

        it 'returns users with applicable_approval_rules' do
          serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

          expect(serialized_user1).to include(
            "id" => user1.id,
            "applicable_approval_rules" => [
              { "id" => 1, "name" => "Rule 2", "rule_type" => "regular" }
            ]
          )
          expect(serialized_user2).to include("id" => user2.id, "applicable_approval_rules" => [])
        end

        context 'with target_branch' do
          let(:options) { super().merge(target_branch: 'my_branch') }

          it 'returns users with applicable_approval_rules' do
            serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

            expect(serialized_user1).to include(
              "id" => user1.id,
              "applicable_approval_rules" => [
                { "id" => 1, "name" => "Rule 2", "rule_type" => "regular" }
              ]
            )
            expect(serialized_user2).to include("id" => user2.id, "applicable_approval_rules" => [])
          end
        end

        context 'with unknown target_branch' do
          let(:options) { super().merge(target_branch: 'unknown_branch') }

          it 'returns users with applicable_approval_rules' do
            serialized_user1, serialized_user2 = serializer.represent([user1, user2], project: project).as_json

            expect(serialized_user1).to include("id" => user1.id, "applicable_approval_rules" => [])
            expect(serialized_user2).to include("id" => user2.id, "applicable_approval_rules" => [])
          end
        end
      end
    end
  end
end
