# frozen_string_literal: true

module Gitlab
  module Graphql
    module ConnectionRedaction
      attr_reader :redactor

      def nodes
        @redacted_nodes ||= redact(super.to_a)
      end

      def redactor=(redactor)
        @redactor = redactor
        @redacted_nodes = nil
      end

      def redact(nodes)
        redactor.present? ? redactor.redact(nodes) : nodes
      end
    end
  end
end
