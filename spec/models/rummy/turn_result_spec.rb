require 'rails_helper'

RSpec.describe Rummy::TurnResult, type: :model do
  let!(:user) { create(:user1) }
  let(:card) { Card.new('2', 'Diamonds') }

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
      other = described_class.new(current_user_id: user.id, card_received_deck: Card.new('K', 'Spades'))
      expect(turn_result).to_not eq other
    end

    it 'is not equal to nil' do
      expect(turn_result).to_not eq(nil)
    end

    it 'is not equal when the received discard card differs' do
      turn_result = described_class.new(current_user_id: user.id, card_received_discard: card)
      other = described_class.new(current_user_id: user.id, card_received_discard: Card.new('K', 'Spades'))
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
end
