# frozen_string_literal: true

module EE
  module Types
    module Boards
      module BoardIssueInputType
        extend ActiveSupport::Concern

        prepended do
          # NONE/ANY epic filter can not be negated
          argument :epic_wildcard_id, ::Types::Boards::EpicWildcardIdEnum,
                   required: false,
                   description: 'Filter by epic ID wildcard. Incompatible with epicId'

          argument :iteration_wildcard_id, ::Types::Boards::IterationWildcardIdEnum,
                   required: false,
                   description: 'Filter by iteration ID wildcard'
        end
      end
    end
  end
end
