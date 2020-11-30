# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # This class updates vulnerabilities entities with state dismissed
      module PopulateDismissedStateForVulnerabilities
        extend ::Gitlab::Utils::Override

        class Vulnerability < ActiveRecord::Base
          self.table_name = 'vulnerabilities'
        end

        override :perform
        def perform(vulnerability_ids)
          Vulnerability.where(id: vulnerability_ids).update_all(state: 2)
        end
      end
    end
  end
end
