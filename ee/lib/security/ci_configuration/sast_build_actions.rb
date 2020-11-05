# frozen_string_literal: true

module Security
  module CiConfiguration
    class SastBuildActions
      SAST_DEFAULT_ANALYZERS = 'bandit, brakeman, eslint, flawfinder, gosec, kubesec, nodejs-scan, phpcs-security-audit, pmd-apex, security-code-scan, sobelow, spotbugs'

      def initialize(auto_devops_enabled, params, existing_gitlab_ci_content)
        @auto_devops_enabled = auto_devops_enabled
        @variables = variables(params)
        @existing_gitlab_ci_content = existing_gitlab_ci_content || {}
        @default_sast_values = default_sast_values(params)
        @default_values_overwritten = false
      end

      def generate
        action = @existing_gitlab_ci_content.present? ? 'update' : 'create'

        update_existing_content!

        [{ action: action, file_path: '.gitlab-ci.yml', content: prepare_existing_content, default_values_overwritten: @default_values_overwritten }]
      end

      private

      def variables(params)
        # This early return is necessary for supporting REST API.
        # Will be removed during the implementation of
        # https://gitlab.com/gitlab-org/gitlab/-/issues/246737
        return params unless params['global'].present?

        collect_values(params, 'value')
      end

      def default_sast_values(params)
        collect_values(params, 'defaultValue')
      end

      def collect_values(config, key)
        global_variables = config['global']&.to_h { |k| [k['field'], k[key]] } || {}
        pipeline_variables = config['pipeline']&.to_h { |k| [k['field'], k[key]] } || {}

        analyzer_variables = collect_analyzer_values(config, key)

        global_variables.merge!(pipeline_variables).merge!(analyzer_variables)
      end

      def collect_analyzer_values(config, key)
        analyzer_variables = config['analyzers']
          &.select {|a| a['enabled'] && a['variables'] }
          &.flat_map {|a| a['variables'] }
          &.collect {|v| [v['field'], v[key]] }.to_h

        analyzer_variables['SAST_DEFAULT_ANALYZERS'] = if key == 'value'
                                                         config['analyzers']
                                                           &.select {|a| a['enabled'] }
                                                           &.collect {|a| a['name'] }
                                                           &.sort
                                                           &.join(', ')
                                                       else
                                                         SAST_DEFAULT_ANALYZERS
                                                       end

        analyzer_variables
      end

      def update_existing_content!
        @existing_gitlab_ci_content['stages'] = set_stages
        @existing_gitlab_ci_content['variables'] = set_variables(global_variables, @existing_gitlab_ci_content)
        @existing_gitlab_ci_content['sast'] = set_sast_block
        @existing_gitlab_ci_content['include'] = set_includes

        @existing_gitlab_ci_content.select! { |k, v| v.present? }
        @existing_gitlab_ci_content['sast'].select! { |k, v| v.present? }
      end

      def set_includes
        includes = @existing_gitlab_ci_content['include'] || []
        includes = includes.is_a?(Array) ? includes : [includes]
        includes << { 'template' => template }
        includes.uniq
      end

      def set_stages
        existing_stages = @existing_gitlab_ci_content['stages'] || []
        base_stages = @auto_devops_enabled ? auto_devops_stages : ['test']
        (existing_stages + base_stages + [sast_stage]).uniq
      end

      def auto_devops_stages
        auto_devops_template = YAML.safe_load( Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content )
        auto_devops_template['stages']
      end

      def sast_stage
        @variables['stage'].presence ? @variables['stage'] : 'test'
      end

      def set_variables(variables, hash_to_update = {})
        hash_to_update['variables'] ||= {}

        variables.each do |key|
          if @variables[key].present? && @variables[key].to_s != @default_sast_values[key].to_s
            hash_to_update['variables'][key] = @variables[key]
            @default_values_overwritten = true
          else
            hash_to_update['variables'].delete(key)
          end
        end

        hash_to_update['variables']
      end

      def set_sast_block
        sast_content = @existing_gitlab_ci_content['sast'] || {}
        sast_content['variables'] = set_variables(sast_variables)
        sast_content['stage'] = sast_stage
        sast_content.select { |k, v| v.present? }
      end

      def prepare_existing_content
        content = @existing_gitlab_ci_content.to_yaml
        content = remove_document_delimeter(content)

        content.prepend(sast_comment)
      end

      def remove_document_delimeter(content)
        content.gsub(/^---\n/, '')
      end

      def sast_comment
        <<~YAML
          # You can override the included template(s) by including variable overrides
          # See https://docs.gitlab.com/ee/user/application_security/sast/#customizing-the-sast-settings
          # Note that environment variables can be set in several places
          # See https://docs.gitlab.com/ee/ci/variables/#priority-of-environment-variables
        YAML
      end

      def template
        return 'Auto-DevOps.gitlab-ci.yml' if @auto_devops_enabled

        'Security/SAST.gitlab-ci.yml'
      end

      def global_variables
        %w(
          SECURE_ANALYZERS_PREFIX
        )
      end

      def sast_variables
        %w(
          SAST_ANALYZER_IMAGE_TAG
          SAST_EXCLUDED_PATHS
          SEARCH_MAX_DEPTH
          SAST_DEFAULT_ANALYZERS
          SAST_BRAKEMAN_LEVEL
          SAST_BANDIT_EXCLUDED_PATHS
          SAST_FLAWFINDER_LEVEL
          SAST_GOSEC_LEVEL
        )
      end
    end
  end
end
