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

  describe '#melded?' do
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs')
                      ])
    end

    it 'is false when the player has no melds' do
      expect(player.melded?).to be false
    end

    it 'is true when the player has at least one meld' do
      player.add_meld(meld)
      expect(player.melded?).to be true
    end
  end

  describe '#try_lay_off' do
    let(:lay_off_card) { Rummy::Card.new('7', 'Diamonds') }
    let(:other_hand_card) { Rummy::Card.new('2', 'Clubs') }
    let(:own_meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('9', 'Spades'),
                        Rummy::Card.new('9', 'Hearts'),
                        Rummy::Card.new('9', 'Clubs')
                      ])
    end
    let(:target_meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs')
                      ])
    end

    before do
      player.add_card(lay_off_card)
      player.add_card(other_hand_card)
    end

    context 'when the player has melded and the cards extend the target meld' do
      before { player.add_meld(own_meld) }

      it 'returns non-nil' do
        expect(player.try_lay_off(target_meld, [lay_off_card])).to_not be_nil
      end

      it 'adds the cards to the target meld' do
        player.try_lay_off(target_meld, [lay_off_card])
        expect(target_meld.cards).to include(lay_off_card)
      end

      it 'removes the laid-off cards from the hand' do
        player.try_lay_off(target_meld, [lay_off_card])
        expect(player.cards).to_not include(lay_off_card)
      end
    end

    context 'when the player has not melded yet' do
      it 'returns nil' do
        expect(player.try_lay_off(target_meld, [lay_off_card])).to be_nil
      end

      it 'does not change the target meld' do
        player.try_lay_off(target_meld, [lay_off_card])
        expect(target_meld.cards).to_not include(lay_off_card)
      end

      it 'does not remove the cards from the hand' do
        player.try_lay_off(target_meld, [lay_off_card])
        expect(player.cards).to include(lay_off_card)
      end
    end

    context 'when a card is not in the player’s hand' do
      let(:run_target) do
        Rummy::Meld.new([
                          Rummy::Card.new('4', 'Diamonds'),
                          Rummy::Card.new('5', 'Diamonds'),
                          Rummy::Card.new('6', 'Diamonds')
                        ])
      end
      let(:card_not_in_hand) { Rummy::Card.new('3', 'Diamonds') }

      before { player.add_meld(own_meld) }

      it 'returns nil' do
        expect(player.try_lay_off(run_target, [card_not_in_hand])).to be_nil
      end

      it 'does not change the target meld' do
        player.try_lay_off(run_target, [card_not_in_hand])
        expect(run_target.cards).to_not include(card_not_in_hand)
      end
    end

    context 'when the cards do not extend the target meld' do
      before { player.add_meld(own_meld) }

      it 'returns nil' do
        expect(player.try_lay_off(target_meld, [other_hand_card])).to be_nil
      end

      it 'does not remove the cards from the hand' do
        player.try_lay_off(target_meld, [other_hand_card])
        expect(player.cards).to include(other_hand_card)
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
