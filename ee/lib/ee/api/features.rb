# frozen_string_literal: true

module EE
  module API
    module Features
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          override :validate_licensed_name!
          def validate_feature_flag_name!(name)
            super

            if License::PLANS_BY_FEATURE[name.to_sym]
              bad_request!(
                "The '#{name}' is a licensed feature name, " \
                "and thus it cannot be used as a feature flag name. " \
                "Use `rails console` to set this feature flag state."
              )
            end
          end
        end
      end
    end
  end
end
