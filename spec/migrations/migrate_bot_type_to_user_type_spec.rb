# frozen_string_literal: true

require 'spec_helper'

require Rails.root.join('db', 'migrate', '20200311074438_migrate_bot_type_to_user_type.rb')

describe MigrateBotTypeToUserType, :migration do
  let(:users) { table(:users) }

  it 'updates bots & ignores humans' do
    users.create!(email: 'human', bot_type: nil, projects_limit: 0)
    users.create!(email: 'support_bot', bot_type: 1, projects_limit: 0)
    users.create!(email: 'alert_bot', bot_type: 2, projects_limit: 0)
    users.create!(email: 'visual_review_bot', bot_type: 3, projects_limit: 0)

    migrate!

    expect(users.where('user_type IS NOT NULL').map(&:user_type)).to match_array([1, 2, 3])
  end
end
