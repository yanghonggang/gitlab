# frozen_string_literal: true

RSpec.shared_examples 'assigning an already assigned reviewer' do |is_multiline|
  before do
    target.reviewers = [reviewer]
  end

  it 'adds multiple reviewers from the list' do
    _, update_params, message = service.execute(note)

    expected_message = is_multiline ? "Assigned @#{user.username} as reviewer. Assigned @#{reviewer.username} as reviewer." : "Assigned @#{reviewer.username} and @#{user.username} as reviewers."

    expect(message).to eq(expected_message)
    expect { service.apply_updates(update_params, note) }.not_to raise_error
  end
end
