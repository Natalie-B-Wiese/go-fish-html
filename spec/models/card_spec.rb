require 'rails_helper'

RSpec.describe Card, type: :model do
  describe '#initialize' do
    it 'has a rank and suit' do
      card = Card.new('A', 'Spades')
      expect(card.rank).to eq 'A'
      expect(card.suit).to eq 'Spades'
    end

    it 'should allow valid ranks' do
      expect do
        Card.new('15', 'Spades')
      end.to raise_error Card::InvalidRank
    end

    it 'should allow valid suits' do
      expect do
        Card.new('2', 'Minecraft')
      end.to raise_error Card::InvalidSuit
    end
  end

  describe '#key' do
    let(:card1) { Card.new('5', 'Spades') }
    let(:card2) { Card.new('J', 'Clubs') }
    let(:card10) { Card.new('10', 'Clubs') }

    it 'converts cards into rank and single letter suit' do
      result1 = card1.key
      expected_result1 = '5S'
      expect(result1).to eq expected_result1

      result2 = card2.key
      expected_result2 = 'JC'
      expect(result2).to eq expected_result2
    end

    it 'works with a 10' do
      result = card10.key
      expected_result = '10C'
      expect(result).to eq expected_result
    end
  end

  describe '.from_key' do
    let(:key1) { '5S' }
    let(:key2) { 'JC' }
    let(:key3) { '4D' }
    let(:key4) { 'AH' }

    it 'creates a card from a key' do
      expect(Card.from_key(key1)).to eq Card.new('5', 'Spades')
      expect(Card.from_key(key2)).to eq Card.new('J', 'Clubs')
      expect(Card.from_key(key3)).to eq Card.new('4', 'Diamonds')
      expect(Card.from_key(key4)).to eq Card.new('A', 'Hearts')
    end

    it 'works with a 10' do
      expect(Card.from_key('10H')).to eq Card.new('10', 'Hearts')
    end
  end

  describe '#==' do
    it 'cards of the same rank and suit are equal' do
      card1 = Card.new('A', 'Spades')
      card2 = Card.new('K', 'Spades')
      card3 = Card.new('A', 'Spades')

      expect(card1).not_to eq card2
      expect(card1).to eq card3
    end
  end

  describe '#value' do
    context 'when rank is 2' do
      it 'returns 0' do
        card = Card.new('2', 'Diamonds')
        result = card.value
        expect(result).to eq 0
      end
    end

    context 'when rank is Ace' do
      it 'returns 0' do
        card = Card.new('A', 'Hearts')
        result = card.value
        expect(result).to eq 12
      end
    end
  end

  describe '#to_s' do
    context 'when rank is 2 and suit is Diamonds' do
      it 'returns correct result' do
        card = Card.new('2', 'Diamonds')
        result = card.to_s
        expect(result).to eq '2 of Diamonds'
      end
    end

    context 'when rank is K and suit is Hearts' do
      it 'returns correct result' do
        card = Card.new('K', 'Hearts')
        result = card.to_s
        expect(result).to eq 'K of Hearts'
      end
    end
  end
end
