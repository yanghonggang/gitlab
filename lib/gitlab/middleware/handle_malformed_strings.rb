# frozen_string_literal: true

module Gitlab
  module Middleware
    # There is no valid reason for a request to contain a malformed string
    # so just return HTTP 400 (Bad Request) if we receive one
    class HandleMalformedStrings
      NULL_BYTE_REGEX = Regexp.new(Regexp.escape("\u0000")).freeze

      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        return [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']] if request_contains_malformed_string?(env)

        app.call(env)
      end

      private

      def request_contains_malformed_string?(request)
        return false if ENV['DISABLE_REQUEST_VALIDATION'] == '1'

        request = Rack::Request.new(request)

        return true if malformed_path?(request.path)

        request.params.values.any? do |value|
          param_has_null_byte?(value)
        end
      end

      def malformed_path?(path)
        string_malformed?(Rack::Utils.unescape(path))
      rescue ArgumentError
        # Rack::Utils.unescape raised this, path is malformed.
        true
      end

      def param_has_null_byte?(value, depth = 0)
        # Guard against possible attack sending large amounts of nested params
        # Should be safe as deeply nested params are highly uncommon.
        return false if depth > 2

        depth += 1

        if value.respond_to?(:match)
          string_malformed?(value)
        elsif value.respond_to?(:values)
          value.values.any? do |hash_value|
            param_has_null_byte?(hash_value, depth)
          end
        elsif value.is_a?(Array)
          value.any? do |array_value|
            param_has_null_byte?(array_value, depth)
          end
        else
          false
        end
      end

      def string_malformed?(string)
        string.match?(NULL_BYTE_REGEX)
      rescue ArgumentError
        # If we're here, we caught a malformed string. Return true
        true
      end
    end
  end
end
