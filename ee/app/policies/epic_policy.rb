# frozen_string_literal: true

class EpicPolicy < BasePolicy
  include CrudPolicyHelpers

  delegate { @subject.group }

  desc 'Epic is confidential'
  condition(:confidential, scope: :subject) do
    @subject.confidential?
  end

  rule { can?(:read_epic) }.policy do
    enable :read_epic_iid
    enable :read_note
  end

  rule { can?(:read_epic) & ~anonymous }.policy do
    enable :create_note
  end

  rule { can?(:create_note) }.enable :award_emoji

  rule { can?(:owner_access) | can?(:maintainer_access) }.enable :admin_note

  desc 'User cannot read confidential epics'
  rule { confidential & ~can?(:reporter_access) }.policy do
    prevent(*create_read_update_admin_destroy(:epic))
    prevent :read_epic_iid
    prevent :create_note
    prevent :award_emoji
    prevent :read_note
  end

  rule { ~anonymous & can?(:read_epic) }.policy do
    enable :create_todo
  end
end
