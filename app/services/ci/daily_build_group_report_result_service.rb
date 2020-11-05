# frozen_string_literal: true

module Ci
  class DailyBuildGroupReportResultService
    def execute(pipeline)
      DailyBuildGroupReportResult.upsert_reports(coverage_reports(pipeline))
    end

    private

    def coverage_reports(pipeline)
      base_attrs = {
        project_id: pipeline.project_id,
        ref_path: pipeline.source_ref_path,
        date: pipeline.created_at.to_date,
        last_pipeline_id: pipeline.id,
        default_branch: pipeline.default_branch?
      }

      aggregate(pipeline.builds.with_coverage).map do |group_name, group|
        base_attrs.merge(
          group_name: group_name,
          data: {
            'coverage' => average_coverage(group)
          }
        )
      end
    end

    def aggregate(builds)
      builds.group_by(&:group_name)
    end

    def average_coverage(group)
      total_coverage = group.reduce(0.0) { |sum, build| sum + build.coverage }
      (total_coverage / group.size).round(2)
    end
  end
end
