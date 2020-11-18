# frozen_string_literal: true

class GroupHook < WebHook
  include CustomModelNaming
  include TriggerableHooks
  include Limitable

  self.limit_name = 'group_hooks'
  self.limit_scope = :group
  self.singular_route_key = :hook

  triggerable_hooks [
    :push_hooks,
    :tag_push_hooks,
    :issue_hooks,
    :confidential_issue_hooks,
    :note_hooks,
    :merge_request_hooks,
    :job_hooks,
    :pipeline_hooks,
    :wiki_page_hooks,
    :deployment_hooks,
    :release_hooks
  ]

  belongs_to :group

  validates :url, presence: true, addressable_url: true

  def pluralized_name
    _('Group Hooks')
  end
end
