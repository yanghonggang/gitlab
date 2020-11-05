# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize
    include ::Gitlab::Graphql::GlobalIDCompatibility

    argument_class ::Types::BaseArgument

    def self.single
      @single ||= Class.new(self) do
        def ready?(**args)
          ready, early_return = super
          [ready, select_result(early_return)]
        end

        def resolve(**args)
          select_result(super)
        end

        def single?
          true
        end

        def select_result(results)
          results&.first
        end
      end
    end

    def self.last
      @last ||= Class.new(self.single) do
        def select_result(results)
          results&.last
        end
      end
    end

    def self.complexity
      0
    end

    def self.resolver_complexity(args, child_complexity:)
      complexity = 1
      complexity += 1 if args[:sort]
      complexity += 5 if args[:search]

      complexity
    end

    def self.complexity_multiplier(args)
      # When fetching many items, additional complexity is added to the field
      # depending on how many items is fetched. For each item we add 1% of the
      # original complexity - this means that loading 100 items (our default
      # maxp_age_size limit) doubles the original complexity.
      #
      # Complexity is not increased when searching by specific ID(s), because
      # complexity difference is minimal in this case.
      [args[:iid], args[:iids]].any? ? 0 : 0.01
    end

    override :object
    def object
      super.tap do |obj|
        # If the field this resolver is used in is wrapped in a presenter, unwrap its subject
        break obj.subject if obj.is_a?(Gitlab::View::Presenter::Base)
      end
    end

    def synchronized_object
      strong_memoize(:synchronized_object) do
        case object
        when BatchLoader::GraphQL
          object.sync
        else
          object
        end
      end
    end

    def single?
      false
    end

    def current_user
      context[:current_user]
    end

    # Overridden in sub-classes (see .single, .last)
    def select_result(results)
      results
    end
  end
end
