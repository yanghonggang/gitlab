# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::EpicIssuesResolver do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project1) { create(:project, :public, group: group) }
  let_it_be(:project2) { create(:project, :private, group: group) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:issue1) { create(:issue, project: project1) }
  let_it_be(:issue2) { create(:issue, project: project1, confidential: true) }
  let_it_be(:issue3) { create(:issue, project: project2) }
  let_it_be(:issue4) { create(:issue, project: project2) }
  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1, relative_position: 3) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic1, issue: issue2, relative_position: 2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: epic2, issue: issue3, relative_position: 1) }
  let_it_be(:epic_issue4) { create(:epic_issue, epic: epic2, issue: issue4, relative_position: nil) }

  let(:epics) { [epic1, epic2] }

  before do
    group.add_developer(current_user)
    stub_licensed_features(epics: true)
  end

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::EpicIssueType.connection_type)
  end

  describe '#resolve' do
    it 'finds all epic issues' do
      result = epics.map { |epic| resolve_epic_issues(epic).to_a }

      expect(result).to eq [[issue2, issue1], [issue3, issue4]]
    end

    it 'finds only epic issues that user can read' do
      guest = create(:user)

      result = epics.map { |e| resolve_epic_issues(e, user: guest).to_a }

      expect(result).to eq [[issue1], []]
    end
  end

  def resolve_epic_issues(object, user: current_user)
    resolve(described_class, obj: object, ctx: { current_user: user })
  end
end
