# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'

require_relative '../../../../rubocop/cop/graphql/id_type'

RSpec.describe RuboCop::Cop::Graphql::IDType, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'adds an offense when GraphQL::ID_TYPE is used as a param to #argument' do
    inspect_source(<<~TYPE)
      argument :some_arg, GraphQL::ID_TYPE, some: other, params: do_not_matter
    TYPE

    expect(cop.offenses.size).to eq 1
  end

  context 'whitelisted arguments' do
    RuboCop::Cop::Graphql::IDType::WHITELISTED_ARGUMENTS.each do |arg|
      it "does not add an offense for calls to #argument with #{arg} as argument name" do
        expect_no_offenses(<<~TYPE.strip)
          argument #{arg}, GraphQL::ID_TYPE, some: other, params: do_not_matter
        TYPE
      end
    end
  end

  it 'does not add an offense for calls to #argument without GraphQL::ID_TYPE' do
    expect_no_offenses(<<~TYPE.strip)
      argument :some_arg, ::Types::GlobalIDType[::Awardable], some: other, params: do_not_matter
    TYPE
  end
end
