# frozen_string_literal: true

module Gitlab
  module Graphql
    module Authorize
      class ObjectAuthorization
        attr_reader :abilities

        def initialize(abilities)
          @abilities = Array.wrap(abilities)
        end

        def ok?(object, current_user)
          return true if abilities.empty?

          abilities.all? do |ability|
            Ability.allowed?(current_user, ability, object)
          end
        end
      end
    end
  end
end
