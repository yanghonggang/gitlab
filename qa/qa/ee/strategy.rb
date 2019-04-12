# frozen_string_literal: true

module QA
  module EE
    module Strategy
      extend self

      def extend_autoloads!
        require 'qa/ee'
      end

      def perform_before_hooks
        # The login page could take some time to load the first time it is visited.
        # We visit the login page and wait for it to properly load only once before the tests.
        QA::Runtime::Browser.visit(:gitlab, QA::Page::Main::Login)
        QA::Page::Main::Login.perform(&:assert_page_loaded)

        return unless ENV['EE_LICENSE']

        EE::Resource::License.fabricate!(ENV['EE_LICENSE'])
      end
    end
  end
end
