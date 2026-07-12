require 'rails_helper'

RSpec.describe CardCollection, type: :model do
  let(:collection_no_cards) { described_class.new([]) }
  let(:collection_with_2_cards) { described_class.new([card1, card2]) }
  let(:collection_with_3_cards) { described_class.new([card1, card2, card3]) }
  let(:collection_with_5_cards) { described_class.new([card1, card2, card3, card4, card5]) }

  let(:card1) { Card.new('3', 'Diamonds') }
  let(:card2) { Card.new('6', 'Spades') }
  let(:card3) { Card.new('2', 'Hearts') }
  let(:card4) { Card.new('4', 'Clubs') }
  let(:card5) { Card.new('J', 'Diamonds') }

  describe '#push_cards' do
    it 'adds card to the bottom of the cards array' do
      collection_no_cards.push_cards(card1)
      collection_no_cards.push_cards(card2)

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card1
      expect(collection_no_cards.cards[1]).to eq card2
    end

    it 'returns card_collection' do
      result = collection_no_cards.push_cards(card1)
      expect(result).to eq collection_no_cards
    end

    it 'works with multiple parameters' do
      collection_no_cards.push_cards(card1, card2)

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card1
      expect(collection_no_cards.cards[1]).to eq card2
    end

    it 'works with an array' do
      collection_no_cards.push_cards([card1, card2])

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card1
      expect(collection_no_cards.cards[1]).to eq card2
    end
  end

  describe '#unshift_cards' do
    it 'adds card to the top of the cards array' do
      collection_no_cards.unshift_cards(card1)
      collection_no_cards.unshift_cards(card2)

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card2
      expect(collection_no_cards.cards[1]).to eq card1
    end

    it 'returns card_collection' do
      result = collection_no_cards.unshift_cards(card1)
      expect(result).to eq collection_no_cards
    end

    it 'works with multiple parameters' do
      collection_no_cards.unshift_cards(card1, card2)

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card1
      expect(collection_no_cards.cards[1]).to eq card2
    end

    it 'works with an array' do
      collection_no_cards.unshift_cards([card1, card2])

      expect(collection_no_cards.cards.length).to eq 2
      expect(collection_no_cards.cards[0]).to eq card1
      expect(collection_no_cards.cards[1]).to eq card2
    end
  end

  describe '#insert_card_at_random' do
    it 'adds a card to the array' do
      collection_no_cards.insert_card_at_random(card1)
      collection_no_cards.insert_card_at_random(card2)
      collection_no_cards.insert_card_at_random(card3)

      expect(collection_no_cards.cards.length).to eq 3
      expect(collection_no_cards.cards).to include card1
      expect(collection_no_cards.cards).to include card2
      expect(collection_no_cards.cards).to include card3
    end

    it 'cards are inserted at a random position' do
      results = []

      5.times do
        collection_no_cards.cards = []
        collection_no_cards.insert_card_at_random(card1)
        collection_no_cards.insert_card_at_random(card2)
        collection_no_cards.insert_card_at_random(card3)
        collection_no_cards.insert_card_at_random(card4)
        collection_no_cards.insert_card_at_random(card5)
        results.push(collection_no_cards.cards.dup) unless results.include?(collection_no_cards.cards)
      end

      expect(results.length).to_not eq 1
    end

    it 'order on previous items is preserved' do
      original_array = [card1, card2, card3, card4]
      collection_no_cards.push_cards(original_array.dup)

      collection_no_cards.insert_card_at_random(card5)
      expect(collection_no_cards.cards - [card5]).to eq original_array
    end

    it 'returns card_collection' do
      result = collection_no_cards.insert_card_at_random(card1)
      expect(result).to eq collection_no_cards
    end
  end

  describe '#pop_card' do
    it 'removes and returns the last card' do
      result = collection_with_3_cards.pop_card
      expect(result).to eq card3
      expect(collection_with_3_cards.cards).to_not include card3
      expect(collection_with_3_cards.cards.length).to eq 2
    end
  end

  describe '#shift_card' do
    it 'removes and returns the first card' do
      result = collection_with_3_cards.shift_card
      expect(result).to eq card1
      expect(collection_with_3_cards.cards).to_not include card1
      expect(collection_with_3_cards.cards.length).to eq 2
    end
  end

  describe '#take_card_at_random' do
    it 'removes and returns a random card' do
      results = []

      5.times do
        collection_with_5_cards.cards = [card1, card2, card3, card4, card5]

        result = collection_with_5_cards.take_card_at_random
        expect(collection_with_5_cards.cards).to_not include result
        expect(collection_with_5_cards.cards.length).to eq 4
        results.push(result) unless results.include?(result)
      end

      expect(results.length).to_not eq 1
    end

    it 'order on previous items is preserved' do
      original_array = [card1, card2, card3, card4, card5]
      collection_no_cards.cards = original_array.dup

      card_taken = collection_no_cards.take_card_at_random
      expect(collection_no_cards.cards).to eq(original_array - [card_taken])
    end
  end

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
