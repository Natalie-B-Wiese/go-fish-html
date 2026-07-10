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

  describe '#take_top_card' do
    it 'returns the top card' do
      deck = Deck.new
      expected_result = deck.top_card
      card = deck.take_top_card
      expect(card).to eq expected_result
    end

    it 'gives a unique card each time' do
      deck = Deck.new
      card1 = deck.take_top_card
      card2 = deck.take_top_card
      expect(card1).not_to eq card2
    end
  end

  describe '#shuffle' do
    it 'shuffles the array' do
      non_shuffled = Deck.new
      shuffled = Deck.new
      shuffled.shuffle

      expect(non_shuffled.cards).not_to eq shuffled.cards
    end
  end
end
