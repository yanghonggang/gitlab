# frozen_string_literal: true

module Terraform
  class StatesFinder
    def initialize(project, current_user)
      @project = project
      @current_user = current_user
    end

    def execute
      return ::Terraform::State.none unless can_read_terraform_states?

      project.terraform_states.ordered_by_name
    end

    private

    attr_reader :project, :current_user

    def can_read_terraform_states?
      current_user.can?(:read_terraform_state, project)
    end
  end
end
