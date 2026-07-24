require 'rails_helper'

RSpec.describe Rummy::Player, type: :model do
  let(:player) { described_class.new(1) }

  describe '#add_card' do
    it 'adds a card to the hand' do
      card = Rummy::Card.new('3', 'Diamonds')

      player.add_card(card)
      expect(player.cards).to include(card)
    end
  end

  describe '#add_meld' do
    it 'adds a meld to the player' do
      meld = Rummy::Meld.new([
                               Rummy::Card.new('7', 'Spades'),
                               Rummy::Card.new('7', 'Hearts'),
                               Rummy::Card.new('7', 'Clubs')
                             ])

      player.add_meld(meld)
      expect(player.melds).to include(meld)
    end
  end

  describe '#try_create_meld' do
    let(:rank) { '7' }
    let(:meld_cards) do
      [
        Rummy::Card.new(rank, 'Spades'),
        Rummy::Card.new(rank, 'Hearts'),
        Rummy::Card.new(rank, 'Clubs')
      ]
    end
    let(:other_card) { Rummy::Card.new('2', 'Clubs') }
    let(:card_not_in_hand) { Rummy::Card.new(rank, 'Diamonds') }

    before do
      meld_cards.each { |card| player.add_card(card) }
      player.add_card(other_card)
    end

    context 'when the cards are in hand and form a valid meld' do
      it 'returns the meld' do
        meld = player.try_create_meld(meld_cards)
        expect(meld.cards).to match_array meld_cards
      end

      it 'adds the meld to the player' do
        player.try_create_meld(meld_cards)
        expect(player.melds.first.cards).to match_array meld_cards
      end

      it 'removes the melded cards from the hand' do
        player.try_create_meld(meld_cards)
        expect(player.cards).to_not include(*meld_cards)
      end
    end

    context 'when a card is not in hand' do
      let(:cards_with_missing) { [meld_cards.first, meld_cards[1], card_not_in_hand] }

      it 'returns nil' do
        expect(player.try_create_meld(cards_with_missing)).to be_nil
      end

      it 'does not remove any cards from the hand' do
        player.try_create_meld(cards_with_missing)
        expect(player.cards).to include(*meld_cards)
      end
    end

    context 'when the cards do not form a valid meld' do
      let(:invalid_cards) { [meld_cards.first, other_card] }

      it 'returns nil' do
        expect(player.try_create_meld(invalid_cards)).to be_nil
      end

      it 'does not remove any cards from the hand' do
        player.try_create_meld(invalid_cards)
        expect(player.cards).to include(*meld_cards, other_card)
      end
    end
  end

  describe '#take_card' do
    let(:card) { Rummy::Card.new('3', 'Diamonds') }
    let(:other_card) { Rummy::Card.new('K', 'Hearts') }

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
    let(:card) { Rummy::Card.new('3', 'Diamonds') }

    before { player.add_card(card) }

    it 'is equal when user_id and hand match' do
      other = described_class.new(1, hand: Rummy::CardCollection.new([card]))
      expect(player).to eq other
    end

    it 'is not equal when user_id differs' do
      other = described_class.new(2, hand: Rummy::CardCollection.new([card]))
      expect(player).to_not eq other
    end

    it 'is not equal when hand differs' do
      other = described_class.new(1)
      expect(player).to_not eq other
    end

    it 'is not equal when melds differ' do
      meld = Rummy::Meld.new([
                               Rummy::Card.new('7', 'Spades'),
                               Rummy::Card.new('7', 'Hearts'),
                               Rummy::Card.new('7', 'Clubs')
                             ])
      other = described_class.new(1, hand: Rummy::CardCollection.new([card]))
      other.add_meld(meld)

      expect(player).to_not eq other
    end

    it 'is not equal to nil' do
      expect(player).to_not eq nil
    end
  end

  describe '#as_json, .from_json' do
    before { player.add_card(Rummy::Card.new('K', 'Hearts')) }

    it 'round-trips through as_json and from_json' do
      restored = described_class.from_json(player.as_json.as_json)
      expect(restored).to eq player
    end

    it 'restores cards as Rummy::Card instances' do
      restored = described_class.from_json(player.as_json.as_json)
      expect(restored.cards).to all(be_a(Rummy::Card))
    end

    it 'round-trips melds through as_json and from_json' do
      meld = Rummy::Meld.new([
                               Rummy::Card.new('7', 'Spades'),
                               Rummy::Card.new('7', 'Hearts'),
                               Rummy::Card.new('7', 'Clubs')
                             ])
      player.add_meld(meld)

      restored = described_class.from_json(player.as_json.as_json)
      expect(restored).to eq player
    end

    it 'restores melds as Rummy::Meld instances' do
      meld = Rummy::Meld.new([
                               Rummy::Card.new('7', 'Spades'),
                               Rummy::Card.new('7', 'Hearts'),
                               Rummy::Card.new('7', 'Clubs')
                             ])
      player.add_meld(meld)

      restored = described_class.from_json(player.as_json.as_json)
      expect(restored.melds).to all(be_a(Rummy::Meld))
    end
  end
end
