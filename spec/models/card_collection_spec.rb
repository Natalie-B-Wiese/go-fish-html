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

  describe '#cards_by_rank' do
    let(:rank1) { 'A' }
    let(:rank2) { '5' }
    let(:other_rank) { '6' }

    let(:card1) { Card.new(rank1, 'Spades') }
    let(:card2) { Card.new(rank2, 'Clubs') }
    let(:card3) { Card.new(rank1, 'Diamonds') }

    before do
      collection_with_3_cards.cards = [card1, card2, card3]
    end

    context 'with no parameters' do
      it 'returns a hash with card groupings' do
        result = collection_with_3_cards.cards_by_rank

        expect(result).to have_key(rank1)
        expect(result).to have_key(rank2)
        expect(result).to_not have_key(other_rank)

        expect(result[rank1]).to eq [card1, card3]
        expect(result[rank2]).to eq [card2]
      end
    end

    context 'with rank parameter' do
      context 'when there are cards with that rank' do
        it 'returns an array of cards in that group' do
          result1 = collection_with_3_cards.cards_by_rank(rank1)
          expect(result1).to eq [card1, card3]

          result2 = collection_with_3_cards.cards_by_rank(rank2)
          expect(result2).to eq [card2]
        end
      end

      context 'when there are no cards with that rank' do
        it 'returns an empty array' do
          result = collection_with_3_cards.cards_by_rank(other_rank)
          expect(result).to be_empty
        end
      end
    end
  end

  describe '#cards_by_suit' do
    let(:suit1) { 'Diamonds' }
    let(:suit2) { 'Hearts' }
    let(:other_suit) { 'Clubs' }

    let(:card1) { Card.new('A', suit1) }
    let(:card2) { Card.new('7', suit2) }
    let(:card3) { Card.new('5', suit1) }

    before do
      collection_with_3_cards.cards = [card1, card2, card3]
    end

    context 'with no parameters' do
      it 'returns a hash with card groupings' do
        result = collection_with_3_cards.cards_by_suit

        expect(result).to have_key(suit1)
        expect(result).to have_key(suit2)
        expect(result).to_not have_key(other_suit)

        expect(result[suit1]).to eq [card1, card3]
        expect(result[suit2]).to eq [card2]
      end
    end

    context 'with suit parameter' do
      context 'when there are cards with that suit' do
        it 'returns an array of cards in that group' do
          result1 = collection_with_3_cards.cards_by_suit(suit1)
          expect(result1).to eq [card1, card3]

          result2 = collection_with_3_cards.cards_by_suit(suit2)
          expect(result2).to eq [card2]
        end
      end

      context 'when there are no cards with that suit' do
        it 'returns an empty array' do
          result = collection_with_3_cards.cards_by_suit(other_suit)
          expect(result).to be_empty
        end
      end
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

    it 'builds cards using .card_class' do
      json = collection_with_2_cards.as_json.transform_keys(&:to_s)
      converted = CardCollection.from_json(json)

      expect(converted.cards).to all(be_a(CardCollection.card_class))
    end
  end

  describe '.card_class' do
    it 'defaults to Card' do
      expect(described_class.card_class).to eq Card
    end
  end

  describe '.cards_to_h' do
    let(:card1) { Card.new('A', 'Spades') }
    let(:card2) { Card.new('2', 'Clubs') }
    let(:card3) { Card.new('3', 'Diamonds') }
    let(:card4) { Card.new('4', 'Hearts') }
    let(:cards) { [card1, card2, card3, card4] }

    it 'it returns a hash of cards passed in' do
      expected_result =
        { 'A of Spades' => 'AS',
          '2 of Clubs' => '2C',
          '3 of Diamonds' => '3D',
          '4 of Hearts' => '4H' }

      result = CardCollection.cards_to_h(cards)
      expect(result).to eq expected_result
    end
  end

  describe '#cards_to_h' do
    let(:card1) { Card.new('A', 'Spades') }
    let(:card2) { Card.new('2', 'Clubs') }
    let(:card3) { Card.new('3', 'Diamonds') }
    let(:card4) { Card.new('4', 'Hearts') }
    let(:cards) { [card1, card2, card3, card4] }

    before do
      collection_no_cards.cards = cards.dup
    end

    it 'it returns a hash of cards in user hand' do
      expected_result =
        { 'A of Spades' => 'AS',
          '2 of Clubs' => '2C',
          '3 of Diamonds' => '3D',
          '4 of Hearts' => '4H' }

      result = collection_no_cards.cards_to_h
      expect(result).to eq expected_result
    end
  end
end
