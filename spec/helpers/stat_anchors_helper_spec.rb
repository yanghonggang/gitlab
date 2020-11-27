# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatAnchorsHelper do
  let(:anchor_klass) { ProjectPresenter::AnchorData }

  describe '#stat_anchor_attrs' do
    subject { helper.stat_anchor_attrs(anchor) }

    context 'when anchor is a link' do
      let(:anchor) { anchor_klass.new(true) }

      it 'returns the proper attributes' do
        expect(subject[:class]).to include('stat-link')
      end
    end

    context 'when anchor is not a link' do
      context 'when class_modifier is set' do
        let(:anchor) { anchor_klass.new(false, nil, nil, 'default') }

        it 'returns the proper attributes' do
          expect(subject[:class]).to include('btn btn-default')
        end
      end

      context 'when class_modifier is not set' do
        let(:anchor) { anchor_klass.new(false) }

        it 'returns the proper attributes' do
          expect(subject[:class]).to include('btn btn-missing')
        end
      end
    end

    context 'when itemprop is not set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, false) }

      it 'returns the itemprop attributes' do
        expect(subject[:itemprop]).to be_nil
      end
    end

    context 'when itemprop is set set' do
      let(:anchor) { anchor_klass.new(false, nil, nil, nil, nil, true) }

      it 'returns the itemprop attributes' do
        expect(subject[:itemprop]).to eq true
      end
    end
  end
end
