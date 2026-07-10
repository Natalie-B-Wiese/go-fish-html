require 'rails_helper'

RSpec.describe CardCollection, type: :model do
  let(:collection_no_cards) { described_class.new([]) }
  let(:collection_with_2_cards) { described_class.new([Card.new('A', 'Spades'), Card.new('5', 'Diamonds')]) }

  describe '#card_count' do
    it 'when empty it returns 0' do
      expect(collection_no_cards.card_count).to eq 0
    end

    it 'returns the number of cards' do
      expect(collection_with_2_cards.card_count).to eq 2
    end
  end

  describe '#empty?' do
    it 'returns false when there are cards' do
      expect(collection_with_2_cards).to_not be_empty
    end

    it 'returns true when there are no cards' do
      expect(collection_no_cards).to be_empty
    end
  end

  describe '==' do
    context 'when card counts are different' do
      it 'returns false' do
        expect(collection_no_cards).to_not eq collection_with_2_cards
      end
    end

    context 'when card counts are the same' do
      context 'when the cards are different' do
        let(:collection_with_2_cards_alt) do
          described_class.new([Card.new('3', 'Hearts'), Card.new('5', 'Diamonds')])
        end

        it 'is not equal' do
          expect(collection_with_2_cards).to_not eq collection_with_2_cards_alt
        end
      end

      context 'when they have the same cards but the order is different' do
        let(:collection_with_2_cards_reversed) { described_class.new(collection_with_2_cards.cards.reverse) }
        it 'is not equal' do
          expect(collection_with_2_cards).to_not eq collection_with_2_cards_reversed
        end
      end

      context 'when they have the same cards and the order is the same' do
        it 'is equal' do
          expect(collection_with_2_cards).to eq collection_with_2_cards
        end
      end
    end
  end

  describe '#as_json and .from_json' do
    it 'it can save and load its data' do
      original = collection_with_2_cards

      json = original.as_json.transform_keys(&:to_s)
      converted = CardCollection.from_json(json)

      expect(converted).to eq original
    end
  end
end
