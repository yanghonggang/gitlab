# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SamlGroupLink do
  describe 'associations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:access_level) }
    it { is_expected.to validate_presence_of(:saml_group_name) }
    it { is_expected.to validate_length_of(:saml_group_name).is_at_most(255) }
    it { is_expected.to define_enum_for(:access_level).with_values(Gitlab::Access.options_with_owner) }

    context 'group name uniqueness' do
      before do
        create(:saml_group_link, group: create(:group))
      end

      it { is_expected.to validate_uniqueness_of(:saml_group_name).scoped_to([:group_id]) }
    end
  end

  describe '.by_id_and_group_id' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_link) { create(:saml_group_link, group: group) }

    it 'finds the group link' do
      results = described_class.by_id_and_group_id(group_link.id, group.id)

      expect(results).to match_array([group_link])
    end

    context 'with multiple groups and group links' do
      let_it_be(:group2) { create(:group) }
      let_it_be(:group_link2) { create(:saml_group_link, group: group2) }

      it 'finds group links within the given groups' do
        results = described_class.by_id_and_group_id([group_link, group_link2], [group, group2])

        expect(results).to match_array([group_link, group_link2])
      end

      it 'does not find group links outside the given groups' do
        results = described_class.by_id_and_group_id([group_link, group_link2], [group])

        expect(results).to match_array([group_link])
      end
    end
  end

  describe '.by_saml_group_name' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_link) { create(:saml_group_link, group: group) }

    it 'finds the group link' do
      results = described_class.by_saml_group_name(group_link.saml_group_name)

      expect(results).to match_array([group_link])
    end

    context 'with multiple groups and group links' do
      let_it_be(:group2) { create(:group) }
      let_it_be(:group_link2) { create(:saml_group_link, group: group2) }

      it 'finds group links within the given groups' do
        results = described_class.by_saml_group_name([group_link.saml_group_name, group_link2.saml_group_name])

        expect(results).to match_array([group_link, group_link2])
      end
    end
  end
end
