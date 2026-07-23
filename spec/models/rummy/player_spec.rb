require 'rails_helper'

RSpec.describe Rummy::Player, type: :model do
  let(:player) { described_class.new(1) }

  describe '#add_card' do
    it 'adds a card to the hand' do
      card = Card.new('3', 'Diamonds')

      player.add_card(card)
      expect(player.cards).to include(card)
    end
  end

  describe '#take_card' do
    let(:card) { Card.new('3', 'Diamonds') }
    let(:other_card) { Card.new('K', 'Hearts') }

    before do
      player.add_card(card)
      player.add_card(other_card)
    end

    it 'removes only the card from the hand' do
      player.take_card(card.rank, card.suit)
      expect(player.cards).to_not include(card)
      expect(player.cards).to include(other_card)
    end

    it 'returns the taken card' do
      expect(player.take_card(card.rank, card.suit)).to eq card
    end
  end

  describe '#==' do
    let(:card) { Card.new('3', 'Diamonds') }

    before { player.add_card(card) }

    it 'is equal when user_id and hand match' do
      other = described_class.new(1, hand: CardCollection.new([card]))
      expect(player).to eq other
    end

    it 'is not equal when user_id differs' do
      other = described_class.new(2, hand: CardCollection.new([card]))
      expect(player).to_not eq other
    end

    it 'is not equal when hand differs' do
      other = described_class.new(1)
      expect(player).to_not eq other
    end

    it 'is not equal to nil' do
      expect(player).to_not eq nil
    end
  end

  describe '#as_json, .from_json' do
    before { player.add_card(Card.new('K', 'Hearts')) }

    it 'round-trips through as_json and from_json' do
      restored = described_class.from_json(player.as_json.as_json)
      expect(restored).to eq player
    end
  end
end
