# frozen_string_literal: true

module Mutations
  module DastScannerProfiles
    class Create < BaseMutation
      include AuthorizesProject

      graphql_name 'DastScannerProfileCreate'

      field :id, ::Types::GlobalIDType[::DastScannerProfile],
            null: true,
            description: 'ID of the scanner profile.'

      field :global_id, ::Types::GlobalIDType[::DastScannerProfile],
            null: true,
            description: 'ID of the scanner profile.',
            deprecated: { reason: 'Use `id`', milestone: '13.6' }

      argument :full_path, GraphQL::ID_TYPE,
               required: true,
               description: 'The project the scanner profile belongs to.'

      argument :profile_name, GraphQL::STRING_TYPE,
                required: true,
                description: 'The name of the scanner profile.'

      argument :spider_timeout, GraphQL::INT_TYPE,
                required: false,
                description: 'The maximum number of minutes allowed for the spider to traverse the site.'

      argument :target_timeout, GraphQL::INT_TYPE,
                required: false,
                description: 'The maximum number of seconds allowed for the site under test to respond to a request.'

      argument :scan_type, Types::DastScanTypeEnum,
                required: false,
                description: 'Indicates the type of DAST scan that will run. ' \
                'Either a Passive Scan or an Active Scan.',
                default_value: 'passive'

      argument :use_ajax_spider, GraphQL::BOOLEAN_TYPE,
                required: false,
                description: 'Indicates if the AJAX spider should be used to crawl the target site. ' \
                'True to run the AJAX spider in addition to the traditional spider, and false to run only the traditional spider.',
                default_value: false

      argument :show_debug_messages, GraphQL::BOOLEAN_TYPE,
                required: false,
                description: 'Indicates if debug messages should be included in DAST console output. ' \
                'True to include the debug messages.',
                default_value: false

      authorize :create_on_demand_dast_scan

      def resolve(full_path:, profile_name:, spider_timeout: nil, target_timeout: nil, scan_type:, use_ajax_spider:, show_debug_messages:)
        project = authorized_find_project!(full_path: full_path)

        service = ::DastScannerProfiles::CreateService.new(project, current_user)
        result = service.execute(
          name: profile_name,
          spider_timeout: spider_timeout,
          target_timeout: target_timeout,
          scan_type: scan_type,
          use_ajax_spider: use_ajax_spider,
          show_debug_messages: show_debug_messages
        )

        if result.success?
          { id: result.payload.to_global_id, global_id: result.payload.to_global_id, errors: [] }
        else
          { errors: result.errors }
        end
      end
    end
  end
end
