# frozen_string_literal: true

module Elastic
  module Latest
    module IssueConfig
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      # ES6 requires a single type per index
      self.document_type = 'issue'
      self.index_name = document_type.pluralize

      settings Elastic::Latest::Config.settings.to_hash

      mappings dynamic: 'strict' do
        indexes :id, type: :integer
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        indexes :iid, type: :integer

        indexes :title, type: :text, index_options: 'positions'
        indexes :description, type: :text, index_options: 'positions'
        indexes :state, type: :keyword
        indexes :project_id, type: :integer

        indexes :visibility_level, type: :integer

        indexes :assignee_id, type: :integer
        indexes :author_id, type: :integer
        indexes :confidential, type: :boolean
      end
    end
  end
end
