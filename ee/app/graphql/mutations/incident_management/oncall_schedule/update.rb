# frozen_string_literal: true

module Mutations
  module IncidentManagement
    module OncallSchedule
      class Update < OncallScheduleBase
        graphql_name 'OncallScheduleUpdate'

        argument :project_path, GraphQL::ID_TYPE,
                 required: true,
                 description: 'The project to update the on-call schedule in'

        argument :iid, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The on-call schedule internal ID to update'

        argument :name, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The name of the on-call schedule'

        argument :description, GraphQL::STRING_TYPE,
                 required: false,
                 description: 'The description of the on-call schedule'

        argument :timezone, GraphQL::STRING_TYPE,
                 required: true,
                 description: 'The timezone of the on-call schedule'

        def resolve(args)
          oncall_schedule = authorized_find!(project_path: args[:project_path], iid: args[:iid])

          response ::IncidentManagement::OncallSchedules::UpdateService.new(
            oncall_schedule,
            current_user,
            args.slice(:name, :description, :timezone)
          ).execute
        end
      end
    end
  end
end
