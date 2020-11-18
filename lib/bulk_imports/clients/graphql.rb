# frozen_string_literal: true

module BulkImports
  module Clients
    class Graphql
      class HTTP < Graphlient::Adapters::HTTP::Adapter
        def execute(document:, operation_name: nil, variables: {}, context: {})
          response = ::Gitlab::HTTP.post(
            url,
            headers: headers,
            follow_redirects: false,
            body: {
              query: document.to_query_string,
              operationName: operation_name,
              variables: variables
            }.to_json
          )

          ::Gitlab::Json.parse(response.body)
        end
      end
      private_constant :HTTP

      attr_reader :client

      delegate :query, :parse, :execute, to: :client

      def initialize(url: Gitlab::COM_URL, token: nil)
        @url = Gitlab::Utils.append_path(url, '/api/graphql')
        @token = token
        @client = Graphlient::Client.new(
          @url,
          options(http: HTTP)
        )
      end

      def options(extra = {})
        return extra unless @token

        {
          headers: {
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@token}"
          }
        }.merge(extra)
      end
    end
  end
end
