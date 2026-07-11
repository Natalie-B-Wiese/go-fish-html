require 'rails_helper'

RSpec.describe CrazyEights::TurnResult, type: :model do
  let!(:user) { create(:user1) }
  let(:card) { Card.new('2', 'Diamonds') }

  describe '#request_message' do
    context 'when card_played is not nil' do
      let!(:turn_result) do
        described_class.new(current_user_id: user.id, card_played: card)
      end
      let(:result) { turn_result.request_message }

      it 'returns a played card message' do
        expect(result).to match(/#{CrazyEights::TurnResult::PLAY_CARD}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to match(/#{card}/)
      end

      it 'does not return a draw from deck message' do
        expect(result).to_not match(/#{CrazyEights::TurnResult::TAKE_DECK}/)
      end
    end

    context 'when card_received_deck is not nil' do
      let!(:turn_result) do
        described_class.new(current_user_id: user.id, card_received_deck: card)
      end

      let(:result) { turn_result.request_message }

      it 'return a draw from deck message without saying the card' do
        expect(result).to match(/#{CrazyEights::TurnResult::TAKE_DECK}/)
        expect(result).to match(/#{user.name}/)
        expect(result).to_not match(/#{card}/)
      end

      it 'does not return a played card message' do
        expect(result).to_not match(/#{CrazyEights::TurnResult::PLAY_CARD}/)
      end
    end
  end

  describe 'serialization round trip' do
    # initialize(current_user_id:, card_played: nil, card_received_deck: nil)
    let!(:turn_result1) do
      described_class.new(current_user_id: user.id, card_played: card)
    end

    let!(:turn_result2) do
      described_class.new(current_user_id: user.id, card_received_deck: card)
    end

    it 'can dump and restore data' do
      json1 = turn_result1.as_json
      restored1 = CrazyEights::TurnResult.from_json(json1)
      expect(restored1).to eq turn_result1

      json2 = turn_result2.as_json
      restored2 = CrazyEights::TurnResult.from_json(json2)
      expect(restored2).to eq turn_result2
    end
  end
end
