require 'rails_helper'

RSpec.describe CrazyEights::Player, type: :model do
  let(:player) { described_class.new(1) }

  describe '#add_card' do
    let(:card1) { Card.new('3', 'Diamonds') }
    let(:card2) { Card.new('5', 'Hearts') }

    it 'adds a card to the hand' do
      player.add_card(card1)

      expect(player.cards).to include(card1)
      expect(player.cards.count).to eq 1
    end

    it 'works multiple times' do
      player.add_card(card1)
      player.add_card(card2)

      expect(player.cards).to include(card1)
      expect(player.cards).to include(card2)
      expect(player.cards.count).to eq 2
    end
  end

  describe '#playable_cards' do
    let(:discard_card) { Card.new('5', 'Hearts') }

    let(:card1) { Card.new(discard_card.rank, 'Spades') }
    let(:card2) { Card.new('2', discard_card.suit) }
    let(:card3) { Card.new('3', discard_card.suit) }
    let(:bad_card) { Card.new('6', 'Diamonds') }

    let(:cards) { [card1, bad_card, card2, card3] }
    let(:good_cards) { cards - [bad_card] }

    before do
      cards.each do |card|
        player.add_card(card)
      end
    end

    it 'it returns an array of cards with either same rank or same suit' do
      result = player.playable_cards(discard_card)
      expect(result).to eq good_cards
    end

    context 'if player has an eight' do
      before do
        player.add_card(Card.new('8', 'Spades'))
      end

      it 'it includes the 8 in all suits' do
        result = player.playable_cards(discard_card)

        expect(result).to include Card.new('8', 'Spades')
        expect(result).to include Card.new('8', 'Clubs')
        expect(result).to include Card.new('8', 'Diamonds')
        expect(result).to include Card.new('8', 'Hearts')

        good_cards.each { |card| expect(result).to include card }
      end
    end
  end

  describe '#take_card' do
    context 'with non-8 card' do
      let(:card) { Card.new('5', 'Diamonds') }
      let(:other_card1) { Card.new(card.rank, 'Hearts') }
      let(:other_card2) { Card.new('2', card.suit) }

      before do
        player.add_card(other_card1)
        player.add_card(other_card2)
        player.add_card(card)
      end

      it 'removes and returns only the card that matches both the rank and suit' do
        result = player.take_card(card.rank, card.suit)
        expect(result).to eq card

        expect(player.cards).to_not include card
        expect(player.cards).to include other_card1
        expect(player.cards).to include other_card2
      end
    end

    context 'with 8 as rank' do
      let(:other_suit) { 'Clubs' }

      let(:card) { Card.new('8', 'Diamonds') }
      let(:other_card1) { Card.new(card.rank, 'Hearts') }
      let(:other_card2) { Card.new('2', card.suit) }

      before do
        player.add_card(other_card2)
        player.add_card(card)
        player.add_card(other_card1)
      end

      it 'returns a card with the same rank and suit as was passed in' do
        result = player.take_card(card.rank, other_suit)
        expect(result).to eq Card.new(card.rank, other_suit)
      end

      it 'removes and returns only the first card with rank 8' do
        player.take_card(card.rank, other_suit)

        expect(player.cards).to_not include card
        expect(player.cards).to include other_card1
        expect(player.cards).to include other_card2
      end
    end
  end
end
