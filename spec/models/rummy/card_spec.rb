require 'rails_helper'

RSpec.describe Rummy::Card, type: :model do
  describe '#value' do
    it 'is 1 for an Ace' do
      card = described_class.new('A', 'Spades')

      expect(card.value).to eq 1
    end

    it 'matches the base Card value for a non-Ace rank' do
      card = described_class.new('7', 'Spades')

      expect(card.value).to eq Card.new('7', 'Spades').value
    end
  end

  describe '.from_key' do
    it 'builds a Rummy::Card' do
      expect(described_class.from_key('7S')).to be_a Rummy::Card
    end
  end
end
