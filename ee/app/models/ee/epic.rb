# frozen_string_literal: true

module EE
  module Epic
    extend ActiveSupport::Concern

    prepended do
      include AtomicInternalId
      include IidRoutes
      include ::Issuable
      include ::Noteable
      include Referable
      include Awardable
      include LabelEventable
      include StateEventable
      include UsageStatistics
      include FromUnion
      include EpicTreeSorting
      include Presentable
      include IdInOrdered
      include Todoable

      enum state_id: {
        opened: ::Epic.available_states[:opened],
        closed: ::Epic.available_states[:closed]
      }

      alias_attribute :state, :state_id

      belongs_to :closed_by, class_name: 'User'

      def reopen
        return if opened?

        update(state: :opened, closed_at: nil, closed_by: nil)
      end

      def close
        return if closed?

        update(state: :closed, closed_at: Time.zone.now)
      end

      belongs_to :assignee, class_name: "User"
      belongs_to :group
      belongs_to :start_date_sourcing_milestone, class_name: 'Milestone'
      belongs_to :due_date_sourcing_milestone, class_name: 'Milestone'
      belongs_to :start_date_sourcing_epic, class_name: 'Epic'
      belongs_to :due_date_sourcing_epic, class_name: 'Epic'
      belongs_to :parent, class_name: "Epic"
      has_many :children, class_name: "Epic", foreign_key: :parent_id
      has_many :events, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent

      has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.epics&.maximum(:iid) }

      has_many :epic_issues
      has_many :issues, through: :epic_issues
      has_many :user_mentions, class_name: "EpicUserMention", dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :boards_epic_user_preferences, class_name: 'Boards::EpicUserPreference', inverse_of: :epic

      validates :group, presence: true
      validate :validate_parent, on: :create
      validate :validate_confidential_issues_and_subepics
      validate :validate_confidential_parent

      alias_attribute :parent_ids, :parent_id
      alias_method :issuing_parent, :group

      scope :for_ids, -> (ids) { where(id: ids) }
      scope :in_parents, -> (parent_ids) { where(parent_id: parent_ids) }
      scope :inc_group, -> { includes(:group) }
      scope :in_selected_groups, -> (groups) { where(group_id: groups) }
      scope :in_milestone, -> (milestone_id) { joins(:issues).where(issues: { milestone_id: milestone_id }) }
      scope :in_issues, -> (issues) { joins(:epic_issues).where(epic_issues: { issue_id: issues }).distinct }
      scope :has_parent, -> { where.not(parent_id: nil) }
      scope :iid_starts_with, -> (query) { where("CAST(iid AS VARCHAR) LIKE ?", "#{sanitize_sql_like(query)}%") }

      scope :with_web_entity_associations, -> { preload(:author, group: [:ip_restrictions, :route]) }

      scope :within_timeframe, -> (start_date, end_date) do
        where('start_date is not NULL or end_date is not NULL')
          .where('start_date is NULL or start_date <= ?', end_date)
          .where('end_date is NULL or end_date >= ?', start_date)
      end

      scope :order_start_or_end_date_asc, -> do
        reorder(Arel.sql("COALESCE(start_date, end_date) ASC NULLS FIRST"))
      end

      scope :order_start_date_asc, -> do
        reorder(::Gitlab::Database.nulls_last_order('start_date'), 'id DESC')
      end

      scope :order_end_date_asc, -> do
        reorder(::Gitlab::Database.nulls_last_order('end_date'), 'id DESC')
      end

      scope :order_end_date_desc, -> do
        reorder(::Gitlab::Database.nulls_last_order('end_date', 'DESC'), 'id DESC')
      end

      scope :order_start_date_desc, -> do
        reorder(::Gitlab::Database.nulls_last_order('start_date', 'DESC'), 'id DESC')
      end

      scope :order_relative_position, -> do
        reorder('relative_position ASC', 'id DESC')
      end

      scope :with_api_entity_associations, -> { preload(:author, :labels, group: :route) }
      scope :start_date_inherited, -> { where(start_date_is_fixed: [nil, false]) }
      scope :due_date_inherited, -> { where(due_date_is_fixed: [nil, false]) }

      scope :counts_by_state, -> { group(:state_id).count }

      scope :public_only, -> { where(confidential: false) }
      scope :confidential, -> { where(confidential: true) }
      scope :not_confidential_or_in_groups, -> (groups) do
        public_only.or(where(confidential: true, group_id: groups))
      end

      MAX_HIERARCHY_DEPTH = 5

      def etag_caching_enabled?
        true
      end

      before_save :set_fixed_start_date, if: :start_date_is_fixed?
      before_save :set_fixed_due_date, if: :due_date_is_fixed?

      def epic_tree_root?
        parent_id.nil?
      end

      def self.epic_tree_node_query(node)
        selection = <<~SELECT_LIST
          id, relative_position, parent_id, parent_id as epic_id, '#{underscore}' as object_type
        SELECT_LIST

        select(selection).in_parents(node.parent_ids)
      end

      private

      def set_fixed_start_date
        self.start_date = start_date_fixed
        self.start_date_sourcing_milestone = nil
        self.due_date_sourcing_epic = nil
      end

      def set_fixed_due_date
        self.end_date = due_date_fixed
        self.due_date_sourcing_milestone = nil
        self.due_date_sourcing_epic = nil
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      # We support internal references (&epic_id) and cross-references (group.full_path&epic_id)
      #
      # Escaped versions with `&amp;` will be extracted too
      #
      # The parent of epic is group instead of project and therefore we have to define new patterns
      def reference_pattern
        @reference_pattern ||= begin
          combined_prefix = Regexp.union(Regexp.escape(reference_prefix), Regexp.escape(reference_prefix_escaped))
          group_regexp = %r{
            (?<!\w)
            (?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
          }x
          %r{
            (#{group_regexp})?
            (?:#{combined_prefix})(?<epic>\d+)
          }x
        end
      end

      def reference_valid?(reference)
        reference.to_i > 0 && reference.to_i <= ::Gitlab::Database::MAX_INT_VALUE
      end

      def link_reference_pattern
        %r{
          (?<url>
            #{Regexp.escape(::Gitlab.config.gitlab.url)}
            \/groups\/(?<group>#{::Gitlab::PathRegex::FULL_NAMESPACE_FORMAT_REGEX})
            \/-\/epics
            \/(?<epic>\d+)
            (?<path>
              (\/[a-z0-9_=-]+)*\/*
            )?
            (?<query>
              \?[a-z0-9_=-]+
              (&[a-z0-9_=-]+)*
            )?
            (?<anchor>\#[a-z0-9_-]+)?
          )
        }x
      end

      def order_by(method)
        case method.to_s
        when 'start_or_end_date' then order_start_or_end_date_asc
        when 'start_date_asc' then order_start_date_asc
        when 'start_date_desc' then order_start_date_desc
        when 'end_date_asc' then order_end_date_asc
        when 'end_date_desc' then order_end_date_desc
        when 'relative_position' then order_relative_position
        else
          super
        end
      end

      override :simple_sorts
      def simple_sorts
        super.merge(
          {
            'start_date_asc' => -> { order_start_date_asc.with_order_id_desc },
            'start_date_desc' => -> { order_start_date_desc.with_order_id_desc },
            'end_date_asc' => -> { order_end_date_asc.with_order_id_desc },
            'end_date_desc' => -> { order_end_date_desc.with_order_id_desc }
          }
        )
      end

      def parent_class
        ::Group
      end

      def nullify_lost_group_parents(groups, lost_groups)
        epics_to_update = in_selected_groups(groups).where(parent: in_selected_groups(lost_groups))
        epics_to_update.update_all(parent_id: nil)
      end

      # Return the deepest relation level for an epic.
      # Example 1:
      # epic1 - parent: nil
      # epic2 - parent: epic1
      # epic3 - parent: epic 2
      # Returns: 3
      # ------------
      # Example 2:
      # epic1 - parent: nil
      # epic2 - parent: epic1
      # Returns: 2
      def deepest_relationship_level
        ::Gitlab::ObjectHierarchy.new(self.where(parent_id: nil)).max_descendants_depth
      end

      def related_issues(ids: nil, preload: nil)
        items = ::Issue.select('issues.*, epic_issues.id as epic_issue_id, epic_issues.relative_position, epic_issues.epic_id as epic_id')
          .joins(:epic_issue)
          .preload(preload)
          .order('epic_issues.relative_position, epic_issues.id')

        return items unless ids

        items.where("epic_issues.epic_id": ids)
      end

      def search(query)
        fuzzy_search(query, [:title, :description])
      end
    end

    def resource_parent
      group
    end

    def assignees
      Array(assignee)
    end

    def project
      nil
    end

    def upcoming?
      start_date&.future?
    end

    def expired?
      end_date&.past?
    end

    def elapsed_days
      return 0 if start_date.nil? || start_date.future?

      (Date.today - start_date).to_i
    end

    # Needed to use EntityDateHelper#remaining_days_in_words
    alias_attribute(:due_date, :end_date)

    def start_date_from_milestones
      start_date_is_fixed? ? start_date_sourcing_milestone&.start_date : start_date
    end

    def due_date_from_milestones
      due_date_is_fixed? ? due_date_sourcing_milestone&.due_date : due_date
    end

    def start_date_from_inherited_source
      start_date_sourcing_milestone&.start_date || start_date_sourcing_epic&.start_date
    end

    def due_date_from_inherited_source
      due_date_sourcing_milestone&.due_date || due_date_sourcing_epic&.end_date
    end

    def start_date_from_inherited_source_title
      start_date_sourcing_milestone&.title || start_date_sourcing_epic&.title
    end

    def due_date_from_inherited_source_title
      due_date_sourcing_milestone&.title || due_date_sourcing_epic&.title
    end

    def to_reference(from = nil, full: false)
      reference = "#{self.class.reference_prefix}#{iid}"

      return reference unless (cross_referenced?(from) && !group.projects.include?(from)) || full

      "#{group.full_path}#{reference}"
    end

    def cross_referenced?(from)
      from && from != group
    end

    def ancestors
      return self.class.none unless parent_id

      hierarchy.ancestors(hierarchy_order: :asc)
    end

    def max_hierarchy_depth_achieved?
      base_and_ancestors.count >= MAX_HIERARCHY_DEPTH
    end

    def descendants
      hierarchy.descendants
    end

    def base_and_descendants
      hierarchy.base_and_descendants
    end

    def has_ancestor?(epic)
      ancestors.exists?(epic.id)
    end

    def has_children?
      children.any?
    end

    def has_issues?
      issues.any?
    end

    def has_parent?
      !!parent_id
    end

    def child?(id)
      children.where(id: id).exists?
    end

    def hierarchy
      ::Gitlab::ObjectHierarchy.new(self.class.where(id: id))
    end

    # we don't support project epics for epics yet, planned in the future #4019
    def update_project_counter_caches
    end

    def valid_parent?(parent_epic: nil, parent_group_descendants: nil)
      self.parent = parent_epic if parent_epic

      validate_parent(parent_group_descendants)

      errors.empty?
    end

    def validate_parent(preloaded_parent_group_and_descendants = nil)
      return unless parent

      preloaded_parent_group_and_descendants ||= parent.group.self_and_descendants

      if self == parent
        errors.add :parent, "This epic cannot be added. An epic cannot be added to itself."
      elsif parent.children.to_a.include?(self)
        errors.add :parent, "This epic cannot be added. It is already assigned to the parent epic."
      elsif parent.has_ancestor?(self)
        errors.add :parent, "This epic cannot be added. It is already an ancestor of the parent epic."
      elsif !preloaded_parent_group_and_descendants.include?(group)
        errors.add :parent, "This epic cannot be added. An epic must belong to the same group or subgroup as its parent epic."
      elsif level_depth_exceeded?(parent)
        errors.add :parent, "This epic cannot be added. One or more epics would exceed the maximum depth (#{MAX_HIERARCHY_DEPTH}) from its most distant ancestor."
      end
    end

    def issues_readable_by(current_user, preload: nil)
      related_issues = self.class.related_issues(ids: id, preload: preload)

      Ability.issues_readable_by_user(related_issues, current_user)
    end

    def mentionable_params
      { group: group, label_url_method: :group_epics_url }
    end

    def discussions_rendered_on_frontend?
      true
    end

    def banzai_render_context(field)
      super.merge(label_url_method: :group_epics_url)
    end

    def level_depth_exceeded?(parent_epic)
      hierarchy.max_descendants_depth.to_i + parent_epic.base_and_ancestors.count >= MAX_HIERARCHY_DEPTH
    end
    private :level_depth_exceeded?

    def base_and_ancestors
      return self.class.none unless parent_id

      hierarchy.base_and_ancestors(hierarchy_order: :asc)
    end

    def validate_confidential_issues_and_subepics
      return unless confidential?

      if issues.public_only.any?
        errors.add :confidential, _('Cannot make the epic confidential if it contains non-confidential issues')
      end

      if children.public_only.any?
        errors.add :confidential, _('Cannot make the epic confidential if it contains non-confidential child epics')
      end
    end

    def validate_confidential_parent
      return unless parent

      if !confidential? && parent.confidential?
        errors.add :confidential, _('A non-confidential epic cannot be assigned to a confidential parent epic')
      end
    end
  end
end
