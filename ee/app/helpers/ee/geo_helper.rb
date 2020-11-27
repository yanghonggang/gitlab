# frozen_string_literal: true

module EE
  module GeoHelper
    STATUS_ICON_NAMES_BY_STATE = {
        synced: 'check',
        pending: 'clock',
        failed: 'warning-solid',
        never: 'status_notfound'
    }.freeze

    def self.current_node_human_status
      return s_('Geo|primary') if ::Gitlab::Geo.primary?
      return s_('Geo|secondary') if ::Gitlab::Geo.secondary?

      s_('Geo|misconfigured')
    end

    def node_vue_list_properties
      version, revision =
        if ::Gitlab::Geo.primary?
          [::Gitlab::VERSION, ::Gitlab.revision]
        else
          status = ::Gitlab::Geo.primary_node&.status

          [status&.version, status&.revision]
        end

      {
        primary_version: version.to_s,
        primary_revision: revision.to_s,
        node_actions_allowed: ::Gitlab::Database.db_read_write?.to_s,
        node_edit_allowed: ::Gitlab::Geo.license_allows?.to_s,
        geo_troubleshooting_help_path: help_page_path('administration/geo/replication/troubleshooting.md'),
        replicable_types: replicable_types.to_json
      }
    end

    def node_namespaces_options(namespaces)
      namespaces.map { |g| { id: g.id, text: g.full_name } }
    end

    def node_selected_namespaces_to_replicate(node)
      node.namespaces.map(&:human_name).sort.join(', ')
    end

    def selective_sync_types_json
      options = {
        ALL: {
          label: s_('Geo|All projects'),
          value: ''
        },
        NAMESPACES: {
          label: s_('Geo|Projects in certain groups'),
          value: 'namespaces'
        },
        SHARDS: {
          label: s_('Geo|Projects in certain storage shards'),
          value: 'shards'
        }
      }

      options.to_json
    end

    def node_class(node)
      klass = []
      klass << 'js-geo-secondary-node' if node.secondary?
      klass << 'node-disabled' unless node.enabled?
      klass
    end

    def toggle_node_button(node)
      btn_class, title, data =
        if node.enabled?
          ['warning', 'Disable', { confirm: 'Disabling a node stops the sync process. Are you sure?' }]
        else
          %w[success Enable]
        end

      link_to title,
              toggle_admin_geo_node_path(node),
              method: :post,
              class: "btn btn-sm btn-#{btn_class}",
              title: title,
              data: data
    end

    def geo_registry_status(registry)
      status_type = case registry.synchronization_state
                    when :failed then
                      'text-danger-500'
                    when :synced then
                      'text-success-600'
                    end

      content_tag(:div, class: "#{status_type}") do
        icon = geo_registry_status_icon(registry)
        text = geo_registry_status_text(registry)

        [icon, text].join(' ').html_safe
      end
    end

    def geo_registry_status_icon(registry)
      sprite_icon(STATUS_ICON_NAMES_BY_STATE.fetch(registry.synchronization_state, 'warning-solid'))
    end

    def geo_registry_status_text(registry)
      case registry.synchronization_state
      when :never
        s_('Geo|Not synced yet')
      when :failed
        s_('Geo|Failed')
      when :pending
        if registry.pending_synchronization?
          s_('Geo|Pending synchronization')
        elsif registry.pending_verification?
          s_('Geo|Pending verification')
        else
          # should never reach this state, unless we introduce new behavior
          s_('Geo|Unknown state')
        end
      when :synced
        s_('Geo|In sync')
      else
        # should never reach this state, unless we introduce new behavior
        s_('Geo|Unknown state')
      end
    end

    def remove_tracking_entry_modal_data(path)
      {
        path: path,
        method: 'delete',
        modal_attributes: {
          title: s_('Geo|Remove tracking database entry'),
          message: s_('Geo|Tracking database entry will be removed. Are you sure?'),
          okVariant: 'danger',
          okTitle: s_('Geo|Remove entry')
        }
      }
    end

    def resync_all_button
      button_to(s_("Geo|Resync all"), { controller: controller_name, action: :resync_all }, class: "btn btn-default btn-md mr-2")
    end

    def reverify_all_button
      button_to(s_("Geo|Reverify all"), { controller: controller_name, action: :reverify_all }, class: "btn btn-default btn-md")
    end

    def replicable_types
      # Hard Coded Legacy Types, we will want to remove these when they are added to SSF
      replicable_types = [
        {
          title: _('Repository'),
          title_plural: _('Repositories'),
          name: 'repository',
          name_plural: 'repositories',
          secondary_view: true
        },
        {
          title: _('Wiki'),
          title_plural: _('Wikis'),
          name: 'wiki',
          name_plural: 'wikis'
        },
        {
          title: _('LFS object'),
          title_plural: _('LFS objects'),
          name: 'lfs_object',
          name_plural: 'lfs_objects'
        },
        {
          title: _('Attachment'),
          title_plural: _('Attachments'),
          name: 'attachment',
          name_plural: 'attachments',
          secondary_view: true
        },
        {
          title: _('Job artifact'),
          title_plural: _('Job artifacts'),
          name: 'job_artifact',
          name_plural: 'job_artifacts'
        },
        {
          title: _('Container repository'),
          title_plural: _('Container repositories'),
          name: 'container_repository',
          name_plural: 'container_repositories'
        },
        {
          title: _('Design repository'),
          title_plural: _('Design repositories'),
          name: 'design_repository',
          name_plural: 'design_repositories',
          secondary_view: true
        }
      ]

      # Adds all the SSF Data Types automatically
      enabled_replicator_classes.each do |replicator_class|
        replicable_types.push(
          {
            title: replicator_class.replicable_title,
            title_plural: replicator_class.replicable_title_plural,
            name: replicator_class.replicable_name,
            name_plural: replicator_class.replicable_name_plural,
            secondary_view: true
          }
        )
      end

      replicable_types
    end

    def enabled_replicator_classes
      ::Gitlab::Geo.enabled_replicator_classes
    end
  end
end
