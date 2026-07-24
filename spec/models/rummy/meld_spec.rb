require 'rails_helper'

RSpec.describe Rummy::Meld, type: :model do
  describe '#initialize' do
    let(:ace) { Rummy::Card.new('A', 'Diamonds') }
    let(:three) { Rummy::Card.new('3', 'Diamonds') }
    let(:five) { Rummy::Card.new('5', 'Diamonds') }

    it 'sorts the cards by value' do
      meld = described_class.new([five, ace, three])

      expect(meld.cards).to eq [ace, three, five]
    end
  end

  describe '#valid?' do
    it 'is invalid if there are less than 3 cards' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be false
    end

    it 'is valid when the cards form a set' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be true
    end

    it 'is valid when the cards form a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be true
    end

    it 'is invalid when the cards form neither a set nor a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('9', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be false
    end
  end

  describe '#set?' do
    it 'is true for three cards of the same rank' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be true
    end

    it 'is false for four of a kind with a mismatched rank mixed in' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs'),
        Rummy::Card.new('8', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be false
    end

    it 'is false for a run' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.set?).to be false
    end
  end

  describe '#run?' do
    it 'is true for an Ace-low run of the same suit' do
      cards = [
        Rummy::Card.new('A', 'Diamonds'),
        Rummy::Card.new('2', 'Diamonds'),
        Rummy::Card.new('3', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be true
    end

    it 'is true for a same-suit run given out of order' do
      cards = [
        Rummy::Card.new('3', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds'),
        Rummy::Card.new('4', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be true
    end

    it 'is false for consecutive ranks with a mismatched suit' do
      cards = [
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('5', 'Diamonds'),
        Rummy::Card.new('6', 'Hearts')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for a same-suit run that is not consecutive' do
      cards = [
        Rummy::Card.new('4', 'Diamonds'),
        Rummy::Card.new('6', 'Diamonds'),
        Rummy::Card.new('8', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for Q-K-A since Aces are low only' do
      cards = [
        Rummy::Card.new('Q', 'Diamonds'),
        Rummy::Card.new('K', 'Diamonds'),
        Rummy::Card.new('A', 'Diamonds')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end

    it 'is false for a set' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.run?).to be false
    end
  end

  describe '#==' do
    let(:cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end
    let(:meld) { described_class.new(cards) }

    it 'is equal when cards match' do
      other = described_class.new(cards.dup)

      expect(meld).to eq other
    end

    it 'is not equal when cards differ' do
      other = described_class.new([Rummy::Card.new('8', 'Diamonds')])

      expect(meld).to_not eq other
    end

    it 'is not equal to nil' do
      expect(meld).to_not eq nil
    end
  end

  describe '#as_json, .from_json' do
    let(:cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end
    let(:meld) { described_class.new(cards) }

    it 'round-trips through as_json and from_json' do
      restored = described_class.from_json(meld.as_json.as_json)

      expect(restored).to eq meld
    end

    it 'restores cards as Rummy::Card instances' do
      restored = described_class.from_json(meld.as_json.as_json)

      expect(restored.cards).to all(be_a(Rummy::Card))
    end
  end
end
