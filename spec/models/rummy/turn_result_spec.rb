require 'rails_helper'

RSpec.describe Rummy::TurnResult, type: :model do
  let!(:user) { create(:user1) }
  let(:card) { Rummy::Card.new('2', 'Diamonds') }
  let(:user_names_by_id) { { user.id => user.name } }

  describe '#request_message' do
    context 'when card_received_deck is present' do
      let(:turn_result) { described_class.new(current_user_id: user.id, card_received_deck: card) }
      let(:result) { turn_result.request_message(user_names_by_id) }

      it 'returns a draw from deck message without saying the card' do
        expect(result).to match(/#{Rummy::TurnResult::TAKE_DECK}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to_not match(/#{card}/)
      end
    end

    context 'when card_received_discard is present' do
      let(:turn_result) { described_class.new(current_user_id: user.id, card_received_discard: card) }
      let(:result) { turn_result.request_message(user_names_by_id) }

      it 'returns a draw from discard message naming the card' do
        expect(result).to match(/#{Rummy::TurnResult::TAKE_DISCARD}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to match(/#{card}/)
      end
    end

    context 'when meld is present without laid_off_cards' do
      let(:meld) do
        Rummy::Meld.new([
                          Rummy::Card.new('7', 'Spades'),
                          Rummy::Card.new('7', 'Hearts'),
                          Rummy::Card.new('7', 'Clubs')
                        ])
      end
      let(:turn_result) { described_class.new(current_user_id: user.id, meld: meld) }
      let(:result) { turn_result.request_message(user_names_by_id) }

      it 'returns a meld message naming the melded cards' do
        expect(result).to match(/#{Rummy::TurnResult::MELD}/)
        expect(result).to match(/#{user.name}/)
        meld.cards.each { |meld_card| expect(result).to match(/#{meld_card}/) }
      end

      it 'does not return a lay-off message' do
        expect(result).to_not match(/#{Rummy::TurnResult::LAY_OFF}/)
      end
    end

    context 'when meld and laid_off_cards are both present' do
      let(:meld) do
        Rummy::Meld.new([
                          Rummy::Card.new('7', 'Spades'),
                          Rummy::Card.new('7', 'Hearts'),
                          Rummy::Card.new('7', 'Clubs'),
                          Rummy::Card.new('7', 'Diamonds')
                        ])
      end
      let(:laid_off_card) { Rummy::Card.new('7', 'Diamonds') }
      let(:turn_result) do
        described_class.new(current_user_id: user.id, meld: meld, laid_off_cards: [laid_off_card])
      end
      let(:result) { turn_result.request_message(user_names_by_id) }

      it 'returns a lay-off message naming the laid-off card' do
        expect(result).to match(/#{Rummy::TurnResult::LAY_OFF}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to match(/#{laid_off_card}/)
      end

      it 'does not return a meld message' do
        expect(result).to_not match(/#{Rummy::TurnResult::MELD}/)
      end
    end

    context 'when card_discarded is present' do
      let(:turn_result) { described_class.new(current_user_id: user.id, card_discarded: card) }
      let(:result) { turn_result.request_message(user_names_by_id) }

      it 'returns a discard message naming the card' do
        expect(result).to match(/#{Rummy::TurnResult::DISCARD}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to match(/#{card}/)
      end
    end
  end

  describe 'serialization round trip' do
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, card_received_deck: card)
    end

    it 'can dump and restore data' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored).to eq turn_result
    end
  end

  describe '#==' do
    let(:turn_result) { described_class.new(current_user_id: user.id, card_received_deck: card) }

    it 'is equal to another result with the same user and card' do
      other = described_class.new(current_user_id: user.id, card_received_deck: card)
      expect(turn_result).to eq other
    end

    it 'is not equal when the current user differs' do
      other = described_class.new(current_user_id: user.id + 1, card_received_deck: card)
      expect(turn_result).to_not eq other
    end

    it 'is not equal when the received card differs' do
      other = described_class.new(current_user_id: user.id, card_received_deck: Rummy::Card.new('K', 'Spades'))
      expect(turn_result).to_not eq other
    end

    it 'is not equal to nil' do
      expect(turn_result).to_not eq(nil)
    end

    it 'is not equal when the received discard card differs' do
      turn_result = described_class.new(current_user_id: user.id, card_received_discard: card)
      other = described_class.new(current_user_id: user.id, card_received_discard: Rummy::Card.new('K', 'Spades'))
      expect(turn_result).to_not eq other
    end
  end

  describe 'serialization round trip for a discard draw' do
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, card_received_discard: card)
    end

    it 'can dump and restore data' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored).to eq turn_result
    end
  end

  describe 'serialization round trip for a discarded card' do
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, card_discarded: card)
    end

    it 'can dump and restore data' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored).to eq turn_result
    end
  end

  describe 'serialization round trip for a lay-off' do
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs'),
                        Rummy::Card.new('7', 'Diamonds')
                      ])
    end
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, meld: meld,
                          laid_off_cards: [Rummy::Card.new('7', 'Diamonds')])
    end

    it 'can dump and restore data' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored).to eq turn_result
    end

    it 'restores the laid-off cards as Rummy::Card instances' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored.laid_off_cards).to all(be_a(Rummy::Card))
    end
  end

  describe '#card_received' do
    context 'when the card was received from the deck' do
      it 'returns the card' do
        turn_result = described_class.new(current_user_id: user.id, card_received_deck: card)
        expect(turn_result.card_received).to eq card
      end
    end

    context 'when the card was received from the discard pile' do
      it 'returns the card' do
        turn_result = described_class.new(current_user_id: user.id, card_received_discard: card)
        expect(turn_result.card_received).to eq card
      end
    end

    context 'when no card was received' do
      it 'returns nil' do
        turn_result = described_class.new(current_user_id: user.id)
        expect(turn_result.card_received).to be_nil
      end
    end
  end

  describe 'serialization round trip for a meld' do
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs')
                      ])
    end
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, meld: meld)
    end

    it 'can dump and restore data' do
      restored = described_class.from_json(turn_result.as_json)
      expect(restored).to eq turn_result
    end
  end

  describe '#== for a meld' do
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs')
                      ])
    end
    let(:turn_result) { described_class.new(current_user_id: user.id, meld: meld) }

    it 'is equal when the meld is the same' do
      other = described_class.new(current_user_id: user.id, meld: meld)

      expect(turn_result).to eq other
    end

    it 'is not equal when the meld differs' do
      other_meld = Rummy::Meld.new([
                                     Rummy::Card.new('8', 'Spades'),
                                     Rummy::Card.new('8', 'Hearts'),
                                     Rummy::Card.new('8', 'Clubs')
                                   ])
      other = described_class.new(current_user_id: user.id, meld: other_meld)

      expect(turn_result).to_not eq other
    end
  end

  describe '#== for a lay-off' do
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs'),
                        Rummy::Card.new('7', 'Diamonds')
                      ])
    end
    let(:laid_off_cards) { [Rummy::Card.new('7', 'Diamonds')] }
    let(:turn_result) do
      described_class.new(current_user_id: user.id, meld: meld, laid_off_cards: laid_off_cards)
    end

    it 'is not equal when the laid-off cards differ' do
      other = described_class.new(current_user_id: user.id, meld: meld,
                                  laid_off_cards: [Rummy::Card.new('8', 'Diamonds')])

      expect(turn_result).to_not eq other
    end
  end

  describe '#== for a discarded card' do
    let(:turn_result) { described_class.new(current_user_id: user.id, card_discarded: card) }

    it 'is not equal when the discarded card differs' do
      other = described_class.new(current_user_id: user.id, card_discarded: Rummy::Card.new('K', 'Spades'))
      expect(turn_result).to_not eq other
    end
  end
end
