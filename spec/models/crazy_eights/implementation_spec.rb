require 'rails_helper'

RSpec.describe CrazyEights::Implementation, type: :model do
  let!(:user1) { create :user1 }
  let!(:user2) { create :user2 }
  let!(:user3) { create :user3 }

  let!(:player1) { CrazyEights::Player.new(user1.id) }
  let!(:player2) { CrazyEights::Player.new(user2.id) }
  let!(:player3) { CrazyEights::Player.new(user3.id) }

  let(:full_deck_size) { 52 }

  def add_cards_to_game_deck(game, num_cards)
    num_cards.times do
      game.deck.cards.push(Card.new('5', 'Hearts'))
    end
  end

  describe '#start!' do
    # Two player game: Deal 5
    # 3+ player game: Deal 7 cards
    # then take the top card and give it to the discard pile (ensure this is not an 8, if it is insert it into the deck at a random index and take a new card), this is the starting card.

    context 'with 2 players' do
      let(:players) { [player1, player2] }
      let(:game) { described_class.new(players) }

      it "deals #{CrazyEights::Implementation::SMALL_GAME_CARDS} cards to each player and 1 to discard pile" do
        game.start!
        expect(player1.hand.cards.length).to eq CrazyEights::Implementation::SMALL_GAME_CARDS
        expect(player2.hand.cards.length).to eq CrazyEights::Implementation::SMALL_GAME_CARDS
        total_cards_dealt_to_players = game.players.count * CrazyEights::Implementation::SMALL_GAME_CARDS
        expect(game.deck.cards.length).to eq full_deck_size - (1 + total_cards_dealt_to_players)
        expect(game.discard_pile.card_count).to eq 1
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.start!
      end
    end

    context 'with 3+ players' do
      let(:players) { [player1, player2, player3] }
      let(:game) { described_class.new(players) }

      it "deals #{CrazyEights::Implementation::BIG_GAME_CARDS} cards to each player and 1 to discard pile" do
        game.start!
        expect(player1.hand.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
        expect(player2.hand.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
        expect(player3.hand.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
        total_cards_dealt_to_players = game.players.count * CrazyEights::Implementation::BIG_GAME_CARDS
        expect(game.deck.cards.length).to eq full_deck_size - (1 + total_cards_dealt_to_players)
        expect(game.discard_pile.card_count).to eq 1
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.start!
      end
    end

    it 'never starts discard pile with an 8' do
      100.times do
        game = described_class.new([player1, player2])
        total_cards_dealt_to_players = game.players.count * CrazyEights::Implementation::SMALL_GAME_CARDS

        game.start!
        expect(game.deck.cards.length).to eq full_deck_size - (1 + total_cards_dealt_to_players)
        expect(game.discard_pile.card_count).to eq 1
        expect(game.discard_pile.cards.first.rank).to_not eq '8'
      end
    end
  end

  describe '#draw_deck_turn' do
    let!(:game) { described_class.new([player1, player2], current_player_index: 0) }

    let(:card1) { Card.new('3', 'Spades') }
    let(:card2) { Card.new('2', 'Diamonds') }
    let(:card3) { Card.new('A', 'Spades') }

    let(:discard_cards) { [card1, card2, card3] }

    before do
      game.start!
      game.discard_pile.cards = discard_cards.dup
    end

    context 'when the player has no playable cards' do
      let(:player1_cards) { [Card.new('5', 'Diamonds'), Card.new('6', 'Clubs')] }

      before do
        player1.hand.cards = player1_cards.dup
      end

      it 'does not switch turns' do
        game.draw_deck_turn
        expect(game.current_player_index).to eq 0
      end

      it 'adds 1 turn result to the feed' do
        game.draw_deck_turn
        expect(game.feed.length).to eq 1
      end

      context 'deck has cards' do
        let(:top_deck_card) { Card.new('5', 'Hearts') }
        let(:other_card) { Card.new('2', 'Diamonds') }

        before do
          game.deck.cards = [top_deck_card, other_card]
        end

        it 'removes the card from the top of the deck and gives to player' do
          game.draw_deck_turn
          expect(game.deck.cards).to_not include top_deck_card
          expect(game.deck.cards).to include other_card

          expect(player1.hand.cards).to include top_deck_card
          expect(player1.hand.cards).to_not include other_card
        end

        it 'returns the correct turn result' do
          result = game.draw_deck_turn
          expect(result.current_user_id).to eq player1.user_id
          expect(result.card_played).to be_nil
          expect(result.card_received_deck).to eq top_deck_card
        end
      end

      context 'deck is empty' do
        before do
          game.deck.cards = []
        end

        it 'creates a new deck from all but top card of discard pile and draws from deck' do
          cards_will_be_in_deck = game.discard_pile.card_count

          # deck does not include top card from discard pile
          cards_will_be_in_deck -= 1

          game.draw_deck_turn

          # player draws a card from the deck
          cards_will_be_in_deck -= 1

          expect(game.discard_pile.card_count).to eq 1
          expect(game.discard_pile.top_card).to eq card1

          expect(game.deck.cards).to_not include card1
          expect(game.deck.cards.length).to eq cards_will_be_in_deck
          expect(player1.hand.cards.count).to eq(player1_cards.count + 1)
        end

        it 'returns the correct turn result' do
          result = game.draw_deck_turn

          expect(result.current_user_id).to eq player1.user_id
          expect(result.card_played).to be_nil
          expect(result.card_received_deck).to_not be_nil
        end
      end
    end

    context 'when the player has a playable card' do
      let(:playable_card) { Card.new(card1.rank, 'Hearts') }
      let(:player1_cards) { [playable_card, Card.new('6', 'Clubs'), Card.new('9', 'Diamonds')] }

      before do
        player1.hand.cards = player1_cards.dup
      end

      it 'does not change the player hand' do
        game.draw_deck_turn
        expect(player1.hand.cards).to eq player1_cards
      end

      it 'does not change the deck' do
        deck_cards = game.deck.cards.dup
        game.draw_deck_turn
        expect(game.deck.cards).to eq deck_cards
      end

      it 'does not change the discard pile' do
        game.draw_deck_turn
        expect(game.discard_pile.cards).to eq discard_cards
      end

      it 'does not switch turns' do
        game.draw_deck_turn
        expect(game.current_player_index).to eq 0
      end

      it 'does not add a turn result to the feed' do
        game.draw_deck_turn
        expect(game.feed).to be_empty
      end

      it 'returns nil' do
        result = game.draw_deck_turn
        expect(result).to be_nil
      end
    end
  end

  describe '#play_turn' do
    let!(:game) { described_class.new([player1, player2], current_player_index: 0) }
    let(:card1) { Card.new('5', 'Spades') }
    let(:rank8) { '8' }
    let(:discard_cards) { [Card.new('3', 'Spades'), Card.new('2', 'Diamonds')] }

    before do
      game.start!
      game.discard_pile.cards = discard_cards
    end

    context 'when the card is in the player hand and playable against the discard pile' do
      let(:player1_cards) { [card1, Card.new(rank8, 'Diamonds'), Card.new(rank8, 'Hearts')] }

      before do
        player1.hand.cards = player1_cards.dup
      end

      it 'adds 1 turn result to the feed' do
        game.play_turn(rank: card1.rank, suit: card1.suit)
        expect(game.feed.length).to eq 1
      end

      it 'removes the card from the player hand and adds it to top of discard pile' do
        game.play_turn(rank: card1.rank, suit: card1.suit)
        expect(player1.hand.cards).to_not include card1
        expect(player1.hand.cards.length).to eq 2
        expect(game.discard_pile.top_card).to eq card1
        expect(game.discard_pile.cards).to include discard_cards.first
      end

      it 'returns the correct turn result' do
        result = game.play_turn(rank: card1.rank, suit: card1.suit)
        expect(result.current_user_id).to eq player1.user_id
        expect(result.card_played).to eq card1
        expect(result.card_received_deck).to be_nil
      end

      it 'switches turns' do
        game.play_turn(rank: card1.rank, suit: card1.suit)
        expect(game.current_player_index).to eq 1
      end
    end

    context 'when the card is not in the player hand at all' do
      let(:player1_cards) { [card1, Card.new(rank8, 'Diamonds'), Card.new(rank8, 'Hearts')] }
      let(:missing_card) { Card.new('6', 'Clubs') }

      before do
        player1.hand.cards = player1_cards.dup
      end

      it 'does not change the player hand' do
        game.play_turn(rank: missing_card.rank, suit: missing_card.suit)
        expect(player1.hand.cards).to eq player1_cards
      end

      it 'does not change the discard pile' do
        game.play_turn(rank: missing_card.rank, suit: missing_card.suit)
        expect(game.discard_pile.cards).to eq discard_cards
      end

      it 'does not switch turns' do
        game.play_turn(rank: missing_card.rank, suit: missing_card.suit)
        expect(game.current_player_index).to eq 0
      end

      it 'does not add a turn result to the feed' do
        game.play_turn(rank: missing_card.rank, suit: missing_card.suit)
        expect(game.feed).to be_empty
      end

      it 'returns nil' do
        result = game.play_turn(rank: missing_card.rank, suit: missing_card.suit)
        expect(result).to be_nil
      end
    end

    context 'when the card is in the player hand but not playable against the discard pile' do
      let(:unplayable_card) { Card.new('6', 'Clubs') }
      let(:player1_cards) { [card1, unplayable_card, Card.new(rank8, 'Diamonds')] }

      before do
        player1.hand.cards = player1_cards.dup
      end

      it 'does not change the player hand' do
        game.play_turn(rank: unplayable_card.rank, suit: unplayable_card.suit)
        expect(player1.hand.cards).to eq player1_cards
      end

      it 'does not change the discard pile' do
        game.play_turn(rank: unplayable_card.rank, suit: unplayable_card.suit)
        expect(game.discard_pile.cards).to eq discard_cards
      end

      it 'does not switch turns' do
        game.play_turn(rank: unplayable_card.rank, suit: unplayable_card.suit)
        expect(game.current_player_index).to eq 0
      end

      it 'does not add a turn result to the feed' do
        game.play_turn(rank: unplayable_card.rank, suit: unplayable_card.suit)
        expect(game.feed).to be_empty
      end

      it 'returns nil' do
        result = game.play_turn(rank: unplayable_card.rank, suit: unplayable_card.suit)
        expect(result).to be_nil
      end
    end
  end

  describe '#game_over?' do
    let!(:game) { described_class.new([player1, player2], current_player_index: 0) }

    before do
      game.start!
    end

    context 'when all players have cards' do
      before do
        player1.hand.cards = [Card.new('5', 'Spades')]
        player2.hand.cards = [Card.new('3', 'Spades')]
      end

      it 'is not over' do
        expect(game.game_over?).to eq false
      end
    end

    context 'when one player is out of cards' do
      before do
        player1.hand.cards = [Card.new('5', 'Spades')]
        player2.hand.cards = []
      end

      it 'is game over' do
        expect(game.game_over?).to eq true
      end
    end
  end

  describe '#winning_player' do
    let!(:game) { described_class.new([player1, player2], current_player_index: 0) }

    before do
      game.start!
    end

    context 'when all players have cards' do
      before do
        player1.hand.cards = [Card.new('5', 'Spades')]
        player2.hand.cards = [Card.new('3', 'Spades')]
      end

      it 'returns nil' do
        expect(game.winning_player).to be_nil
      end
    end

    context 'when player is out of cards' do
      it 'returns the player who is out of cards' do
        player1.hand.cards = []
        player2.hand.cards = [Card.new('5', 'Spades')]
        expect(game.winning_player).to eq player1

        player1.hand.cards = [Card.new('5', 'Spades')]
        player2.hand.cards = []
        expect(game.winning_player).to eq player2
      end
    end
  end
end
