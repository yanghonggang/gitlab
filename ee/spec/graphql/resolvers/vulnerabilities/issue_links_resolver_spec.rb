# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Vulnerabilities::IssueLinksResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:vulnerability) { create(:vulnerability) }

  subject { resolve(described_class, obj: vulnerability, args: filters, ctx: { current_user: user }) }

  describe '#ready?' do
    context 'when the link_type filter is given but is not `CREATED` or `RELATED` ' do
      context 'when the filter is a string' do
        let(:filters) { { link_type: 'some string' } }

        it { expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'Provide a valid vulnerability issue link type') }
      end

      context 'when the filter is a number' do
        let(:filters) { { link_type: 99 } }

        it { expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError), 'Provide a valid vulnerability issue link type' }
      end

      context 'when the filter is a symbol' do
        let(:filters) { { link_type: :CREATED } }

        it { expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError), 'Provide a valid vulnerability issue link type' }
      end
    end
  end

  describe '#resolve' do
    let_it_be(:related_issue) { create(:vulnerabilities_issue_link, :related, vulnerability: vulnerability) }
    let_it_be(:created_issue) { create(:vulnerabilities_issue_link, :created, vulnerability: vulnerability) }

    context 'when there is no filter given' do
      let(:filters) { {} }

      it { is_expected.to match_array([related_issue, created_issue]) }
      it { expect { subject }.not_to raise_error }
    end

    context 'when the link_type filter is given' do
      context 'when the filter is `CREATED`' do
        let(:filters) { { link_type: 'CREATED' } }

        it { is_expected.to match_array([created_issue]) }
        it { expect { subject }.not_to raise_error }
      end

      context 'when the filter is `RELATED`' do
        let(:filters) { { link_type: 'RELATED' } }

        it { is_expected.to match_array([related_issue]) }
        it { expect { subject }.not_to raise_error }
      end
    end
  end
end
