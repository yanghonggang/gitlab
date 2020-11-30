# frozen_string_literal: true

module Mutations
  module ComplianceManagement
    module Frameworks
      class Destroy < ::Mutations::BaseMutation
        graphql_name 'DestroyComplianceFramework'

        argument :id,
                 ::Types::GlobalIDType[::ComplianceManagement::Framework],
                 required: true,
                 description: 'The global ID of the compliance framework to destroy'

        def resolve(id:)
          result = ::ComplianceManagement::Frameworks::DestroyService.new(framework: framework(id), current_user: current_user).execute

          { errors: result.success? ? [] : Array.wrap(result.message) }
        end

        private

        def framework(gid)
          GlobalID::Locator.locate gid
        end
      end
    end
  end
end
