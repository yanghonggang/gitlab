# frozen_string_literal: true

module IncidentManagement
  class ApplyIncidentSlaExceededLabelWorker
    include ApplicationWorker

    idempotent!
    feature_category :incident_management

    def perform(incident_id)
      @incident = Issue.find_by_id(incident_id)
      @project = incident&.project

      return unless incident && project

      @label = incident_exceeded_sla_label
      return if incident.label_ids.include?(label.id)

      incident.labels << label
      add_resource_event
    end

    private

    attr_reader :incident, :project, :label

    def add_resource_event
      ResourceEvents::ChangeLabelsService
        .new(incident, User.alert_bot)
        .execute(added_labels: [label])
    end

    def incident_exceeded_sla_label
      ::IncidentManagement::CreateIncidentSlaExceededLabelService
        .new(project)
        .execute
        .payload[:label]
    end
  end
end
