# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::VulnerabilitiesGradeResolver do
  include GraphqlHelpers

  subject { resolve(described_class, obj: group, args: args, ctx: { current_user: user }).execute }

  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:project_in_subgroup) { create(:project, namespace: subgroup) }
  let_it_be(:user) { create(:user) }

  let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :grade_f, project: project) }
  let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :grade_d, project: project_in_subgroup) }

  describe '#resolve' do
    let(:args) { { include_subgroups: include_subgroups } }

    context 'when include_subgroups is set to true' do
      let(:include_subgroups) { true }

      it 'returns project grades for projects in group and its subgroups' do
        expect(subject.map(&:grade)).to match_array(%w[d f])
      end
    end

    context 'when include_subgroups is set to true' do
      let(:include_subgroups) { false }

      it 'returns project grades for projects in group only' do
        expect(subject.map(&:grade)).to match_array(%w[f])
      end
    end
  end
end
