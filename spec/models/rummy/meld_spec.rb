require 'rails_helper'

RSpec.describe Rummy::Meld, type: :model do
  describe '#valid?' do
    it 'is valid for three cards of the same rank' do
      cards = [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]

      meld = described_class.new(cards)

      expect(meld.valid?).to be true
    end
  end
end
