# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Update do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }

  let(:new_labels) { %w(new_label1 new_label2) }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:mutated_board) { subject[:board] }

  let(:mutation_params) do
    {
      id: board.to_global_id,
      name: 'Test board 1',
      hide_backlog_list: true,
      hide_closed_list: true,
      weight: 3,
      assignee_id: user.to_global_id,
      milestone_id: milestone.to_global_id,
      label_ids: [label1.to_global_id, label2.to_global_id]
    }
  end

  subject { mutation.resolve(**mutation_params) }

  specify { expect(described_class).to require_graphql_authorizations(:admin_board) }

  describe '#resolve' do
    context 'when the user cannot admin the board' do
      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'with invalid params' do
      it 'raises an error' do
        mutation_params[:id] = project.to_global_id

        expect { subject }.to raise_error(::GraphQL::CoercionError)
      end
    end

    context 'when user can update board' do
      before do
        board.resource_parent.add_reporter(user)
      end

      it 'updates board with correct values' do
        expected_attributes = {
          name: 'Test board 1',
          hide_backlog_list: true,
          hide_closed_list: true,
          weight: 3,
          assignee: user,
          milestone: milestone,
          labels: contain_exactly(label1, label2)
        }

        subject

        expect(board.reload).to have_attributes(expected_attributes)
      end

      context 'when passing labels param' do
        before do
          mutation_params.delete(:label_ids)
          mutation_params.merge!(labels: new_labels)
        end

        it 'updates board with correct labels' do
          subject

          expect(board.reload.labels.pluck(:title)).to match_array(new_labels)
        end
      end
    end
  end

  describe '#ready' do
    context 'when passing both labels & label_ids param' do
      before do
        mutation_params.merge!(labels: new_labels)
      end

      it 'raises exception when mutually exclusive params are given' do
        expect { mutation.ready?(**mutation_params) }
          .to raise_error(Gitlab::Graphql::Errors::ArgumentError, /one and only one of/)
      end
    end
  end
end
