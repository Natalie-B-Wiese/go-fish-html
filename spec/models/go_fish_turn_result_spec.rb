require 'rails_helper'

RSpec.describe GoFish::TurnResult, type: :model do
  let!(:user) { create(:user1) }
  let!(:opponent) { create(:user2) }

  let(:rank_requested) { '4' }
  let(:other_rank) { '3' }

  describe '#request_message' do
    context 'when player requests card from opponent' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, opponent_user_id: opponent.id, rank_requested: rank_requested)
      end

      it 'returns request message' do
        result = turn_result.request_message
        expect(result).to match(/#{GoFish::TurnResult::REQUEST}/o)
        expect(result).to match(/#{user.name}.*#{opponent.name}/)
        expect(result).to match(/#{rank_requested}/)
      end
    end

    context 'when player is out of cards' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, card_received_deck: Card.new(rank_requested, 'Spades'))
      end

      it 'returns out of cards message' do
        result = turn_result.request_message
        expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::NO_CARDS}/)
      end
    end

    context 'when player has cards' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, opponent_user_id: opponent.id, rank_requested: rank_requested)
      end

      it 'does not return out of cards message' do
        result = turn_result.request_message
        expect(result).to_not match(/#{user.name}.*#{GoFish::TurnResult::NO_CARDS}/)
      end
    end
  end

  describe '#action_message' do
    context 'when player does not have cards' do
      let(:turn_result) { described_class.new(current_user_id: user.id) }

      it 'returns an empty string' do
        result = turn_result.action_message
        expect(result).to eq ''
      end
    end

    context 'when player made a request and receives from opponent' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                            rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')])
      end

      it 'returns receive from opponent message' do
        result = turn_result.action_message
        expect(result).to match(/#{opponent.name}.*1 card.*#{user.name}/)
      end
    end

    context 'when player made a request and receives multiple cards from opponent' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                            rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades'), Card.new(rank_requested, 'Hearts')])
      end

      it 'returns receive from opponent message' do
        result = turn_result.action_message
        expect(result).to match(/#{opponent.name}.*2 cards.*#{user.name}/)
      end
    end

    context 'when player made a request and does not receive a card from opponent' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                            rank_requested: rank_requested)
      end

      it 'returns go fish message' do
        result = turn_result.action_message
        expect(result).to match(/#{GoFish::TurnResult::GO_FISH}.*#{opponent.name}.* #{rank_requested}/)
      end
    end
  end

  describe '#result_message' do
    context 'when player is out of cards and deck has cards' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id, card_received_deck: Card.new(rank_requested, 'Spades'))
      end

      it 'does not return deck empty message' do
        result = turn_result.result_message
        expect(result).to_not match(/#{GoFish::TurnResult::EMPTY_DECK}/o)
      end

      it 'returns go again message' do
        result = turn_result.result_message
        expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
      end

      it 'returns card draw from deck message' do
        result = turn_result.result_message
        expect(result).to match(/#{GoFish::TurnResult::TAKE_DECK}/o)
      end

      it 'does not show the rank drawn from the deck' do
        result = turn_result.result_message
        expect(result).to_not match(/#{other_rank}/)
        expect(result).to_not match(/#{rank_requested}/)
      end
    end

    context 'when player is out of cards and deck is out of cards' do
      let(:turn_result) do
        described_class.new(current_user_id: user.id)
      end

      it 'does not return card draw from deck message' do
        result = turn_result.result_message
        expect(result).to_not match(/#{GoFish::TurnResult::TAKE_DECK}/o)
      end

      it 'returns deck empty message' do
        result = turn_result.result_message
        expect(result).to match(/#{GoFish::TurnResult::EMPTY_DECK}/o)
      end

      it 'does not return go again message' do
        result = turn_result.result_message
        expect(result).to_not match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
      end

      it 'returns disqualified message' do
        result = turn_result.result_message
        expect(result).to match(/#{GoFish::TurnResult::DISQUALIFIED}/o)
      end
    end

    context 'when player receives requested card from opponent' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')])
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'does not return card draw from deck message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{GoFish::TurnResult::TAKE_DECK}/o)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, cards_received_opponent: [Card.new(rank_requested, 'Spades')], was_book_made: true)
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'does not return card draw from deck message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{GoFish::TurnResult::TAKE_DECK}/o)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end
    end

    context 'when player receives requested card from deck' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, card_received_deck: Card.new(rank_requested, 'Spades'))
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'returns a draw from deck message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::TAKE_DECK}/o)
        end

        it 'shows the rank drawn from the deck' do
          result = turn_result.result_message
          expect(result).to match(/#{rank_requested}/)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, card_received_deck: Card.new(rank_requested, 'Spades'), was_book_made: true)
        end

        it 'returns go again message' do
          result = turn_result.result_message
          expect(result).to match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'returns a draw from deck message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::TAKE_DECK}/o)
        end

        it 'shows the rank drawn from the deck' do
          result = turn_result.result_message
          expect(result).to match(/#{rank_requested}/)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end
    end

    context 'when player does not receive requested card' do
      context 'when was_book_made is false' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, card_received_deck: Card.new(other_rank, 'Spades'))
        end

        it 'returns card draw from deck message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::TAKE_DECK}/o)
        end

        it 'does not show the rank drawn from the deck' do
          result = turn_result.result_message
          expect(result).to_not match(/#{other_rank}/)
          expect(result).to_not match(/#{rank_requested}/)
        end

        it 'does not return go again message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'does not return book message' do
          result = turn_result.result_message
          expect(result).not_to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end

      context 'when was_book_made is true' do
        let(:turn_result) do
          described_class.new(current_user_id: user.id, opponent_user_id: opponent.id,
                              rank_requested: rank_requested, card_received_deck: Card.new(other_rank, 'Spades'), was_book_made: true)
        end

        it 'does not return go again message' do
          result = turn_result.result_message
          expect(result).to_not match(/#{user.name}.*#{GoFish::TurnResult::GO_AGAIN}/)
        end

        it 'shows the card rank' do
          result = turn_result.result_message
          expect(result).to match(/#{other_rank}/)
        end

        it 'returns book message' do
          result = turn_result.result_message
          expect(result).to match(/#{GoFish::TurnResult::BOOK}/o)
        end
      end
    end
  end

  describe 'serialization round trip' do
    let!(:turn_result) do
      described_class.new(current_user_id: user.id, opponent_user_id: opponent.id, rank_requested: rank_requested)
    end

    it 'can dump and restore data' do
      json = turn_result.as_json
      restored = GoFish::TurnResult.from_json(json)
      expect(restored).to eq turn_result
    end
  end
end
