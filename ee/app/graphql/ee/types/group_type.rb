# frozen_string_literal: true

module EE
  module Types
    module GroupType
      extend ActiveSupport::Concern

      prepended do
        %i[epics group_timelogs].each do |feature|
          field "#{feature}_enabled", GraphQL::BOOLEAN_TYPE, null: true, resolve: -> (group, args, ctx) do
            group.feature_available?(feature)
          end, description: "Indicates if #{feature.to_s.humanize} are enabled for namespace"
        end

        field :epic, ::Types::EpicType, null: true,
              description: 'Find a single epic',
              resolver: ::Resolvers::EpicsResolver.single

        field :epics, ::Types::EpicType.connection_type, null: true,
              description: 'Find epics',
              extras: [:lookahead],
              max_page_size: 2000,
              resolver: ::Resolvers::EpicsResolver

        field :iterations, ::Types::IterationType.connection_type, null: true,
              description: 'Find iterations',
              resolver: ::Resolvers::IterationsResolver

        field :timelogs, ::Types::TimelogType.connection_type, null: false,
              description: 'Time logged in issues by group members',
              extras: [:lookahead],
              complexity: 5,
              resolver: ::Resolvers::TimelogResolver

        field :vulnerabilities,
              ::Types::VulnerabilityType.connection_type,
              null: true,
              description: 'Vulnerabilities reported on the projects in the group and its subgroups',
              resolver: ::Resolvers::VulnerabilitiesResolver

        field :vulnerability_scanners,
              ::Types::VulnerabilityScannerType.connection_type,
              null: true,
              description: 'Vulnerability scanners reported on the project vulnerabilties of the group and its subgroups',
              resolver: ::Resolvers::Vulnerabilities::ScannersResolver

        field :vulnerability_severities_count, ::Types::VulnerabilitySeveritiesCountType, null: true,
              description: 'Counts for each vulnerability severity in the group and its subgroups',
              resolver: ::Resolvers::VulnerabilitySeveritiesCountResolver

        field :vulnerabilities_count_by_day,
              ::Types::VulnerabilitiesCountByDayType.connection_type,
              null: true,
              description: 'Number of vulnerabilities per day for the projects in the group and its subgroups',
              resolver: ::Resolvers::VulnerabilitiesCountPerDayResolver

        field :vulnerabilities_count_by_day_and_severity,
              ::Types::VulnerabilitiesCountByDayAndSeverityType.connection_type,
              null: true,
              description: 'Number of vulnerabilities per severity level, per day, for the projects in the group and its subgroups',
              resolver: ::Resolvers::VulnerabilitiesHistoryResolver,
              deprecated: { reason: 'Use `vulnerabilitiesCountByDay`', milestone: '13.3' }

        field :vulnerability_grades,
              [::Types::VulnerableProjectsByGradeType],
              null: false,
              description: 'Represents vulnerable project counts for each grade',
              resolver: ::Resolvers::VulnerabilitiesGradeResolver

        field :code_coverage_activities,
              ::Types::Ci::CodeCoverageActivityType.connection_type,
              null: true,
              description: 'Represents the code coverage activity for this group',
              resolver: ::Resolvers::Ci::CodeCoverageActivitiesResolver,
              feature_flag: :group_coverage_data_report_graph
      end
    end
  end
end
