# frozen_string_literal: true

module EE
  module API
    module Entities
      class Experiment < Grape::Entity
        expose :key
        expose :enabled
      end
    end
  end
end
