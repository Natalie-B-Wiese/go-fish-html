require 'rails_helper'

RSpec.describe Deck, type: :model do
  it 'Should have 52 cards when created' do
    deck = Deck.new
    expect(deck.cards.count).to eq 52
  end

  describe '#top_card' do
    it 'returns the top card without removing it' do
      deck = Deck.new
      expected_result = deck.cards.first

      2.times do
        card = deck.top_card
        expect(card).to eq expected_result
      end
    end
  end

  describe '#shuffle' do
    it 'shuffles the array' do
      non_shuffled = Deck.new
      shuffled = Deck.new
      shuffled.shuffle

      expect(non_shuffled.cards).not_to eq shuffled.cards
    end

    context 'with a single card' do
      it 'does not hang' do
        deck = Deck.new([Card.new('5', 'Hearts')])
        expect { deck.shuffle }.to_not raise_error
      end
    end

    context 'with no cards' do
      it 'does not hang' do
        deck = Deck.new([])
        expect { deck.shuffle }.to_not raise_error
      end
    end
  end
end
