# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupLevel
      include ::CycleAnalytics::LevelBase

      attr_reader :options, :group

      def initialize(group:, options:)
        @group = group
        @options = options.merge(group: group)
      end

      def summary
        @summary ||=
          Gitlab::Analytics::CycleAnalytics::Summary::Group::StageSummary
          .new(group, options: options)
          .data
      end

      def time_summary
        @time_summary ||=
          Gitlab::Analytics::CycleAnalytics::GroupStageTimeSummary
          .new(group, options: options)
          .data
      end

      def permissions(*)
        STAGES.each_with_object({}) do |stage, obj|
          obj[stage] = true
        end
      end

      def stats
        @stats ||= STAGES.map do |stage_name|
          self[stage_name].as_json(serializer: GroupAnalyticsStageSerializer)
        end
      end

      def build_stage(stage_name)
        stage_params = stage_params_by_name(stage_name).merge(group: group)
        Analytics::CycleAnalytics::GroupStage.new(stage_params)
      end

      def subject_class
        group
      end
    end
  end
end
