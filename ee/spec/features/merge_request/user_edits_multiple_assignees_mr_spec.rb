# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User edits MR with multiple assignees' do
  include_context 'merge request edit context'

  before do
    stub_licensed_features(multiple_merge_request_assignees: true)
  end

  it_behaves_like 'multiple assignees merge request', 'updates', 'Save changes'
end
