# frozen_string_literal: true

module ElasticsearchHelpers
  def assert_named_queries(*expected_names)
    es_host = Gitlab::CurrentSettings.elasticsearch_url.first
    search_uri =
      Addressable::Template.new("#{es_host}/{index}/doc/_search{?params*}")

    ensure_names_present = lambda do |req|
      payload = Gitlab::Json.parse(req.body)
      query = payload["query"]

      return false unless query.present?

      inspector = ElasticQueryNameInspector.new

      inspector.inspect(query)
      inspector.has_named_query?(*expected_names)
    rescue ::JSON::ParserError
      false
    end

    a_named_query = a_request(:get, search_uri).with(&ensure_names_present)
    message = "Expected a query with the following names: #{expected_names.inspect}"
    expect(a_named_query).to have_been_made.at_least_once, message
  end

  def ensure_elasticsearch_index!
    # Ensure that any enqueued updates are processed
    Elastic::ProcessBookkeepingService.new.execute
    Elastic::ProcessInitialBookkeepingService.new.execute

    # Make any documents added to the index visible
    refresh_index!
  end

  def refresh_index!
    es_helper.refresh_index
    es_helper.refresh_index(index_name: @migrations_index_name) # rubocop:disable Gitlab/ModuleWithInstanceVariables
  end

  def es_helper
    Gitlab::Elastic::Helper.default
  end
end
