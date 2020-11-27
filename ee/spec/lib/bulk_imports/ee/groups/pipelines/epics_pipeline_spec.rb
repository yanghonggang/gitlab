# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::EE::Groups::Pipelines::EpicsPipeline do
  describe '#run' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }
    let(:entity) do
      create(
        :bulk_import_entity,
        source_full_path: 'source/full/path',
        destination_name: 'My Destination Group',
        destination_namespace: group.full_path,
        group: group
      )
    end

    let(:context) do
      BulkImports::Pipeline::Context.new(
        current_user: user,
        entity: entity
      )
    end

    subject { described_class.new }

    it 'imports group epics into destination group' do
      page1 = extractor_data(has_next_page: true, cursor: 'nextPageCursor')
      page2 = extractor_data(has_next_page: false)

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        if entity.has_next_page?(:epics)
          allow(extractor).to receive(:extract).and_return(page2)
        else
          allow(extractor).to receive(:extract).and_return(page1)
        end
      end

      expect { subject.run(context) }.to change(::Epic, :count).by(2)
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.extractors)
        .to contain_exactly(
          {
            klass: BulkImports::Common::Extractors::GraphqlExtractor,
            options: {
              query: BulkImports::EE::Groups::Graphql::GetEpicsQuery
            }
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::HashKeyDigger, options: { key_path: %w[data group epics] } },
          { klass: BulkImports::Common::Transformers::UnderscorifyKeysTransformer, options: nil }
        )
    end

    it 'has loaders' do
      expect(described_class.loaders).to contain_exactly({
        klass: BulkImports::EE::Groups::Loaders::EpicsLoader, options: nil
      })
    end
  end

  def extractor_data(has_next_page:, cursor: nil)
    [
      {
        'data' => {
          'group' => {
            'epics' => {
              'page_info' => {
                'end_cursor' => cursor,
                'has_next_page' => has_next_page
              },
              'nodes' => [
                {
                  'title' => 'epic1',
                  'state' => 'closed',
                  'confidential' => true
                }
              ]
            }
          }
        }
      }
    ]
  end
end
