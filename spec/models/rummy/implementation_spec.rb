require 'rails_helper'

RSpec.describe Rummy::Implementation, type: :model do
  let(:players) { user_ids.map { |id| Rummy::Player.new(id) } }
  let(:game) { described_class.new(players) }

  describe '#start!' do
    context 'with 2 players' do
      let(:user_ids) { [1, 2] }

      it "deals #{Rummy::Implementation::SMALL_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::SMALL_GAME_CARDS }
      end

      it 'shuffles the deck' do
        expect(game.deck).to receive(:shuffle)
        game.start!
      end
    end

    context 'with 3 or 4 players' do
      let(:user_ids) { [1, 2, 3, 4] }

      it "deals #{Rummy::Implementation::MEDIUM_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::MEDIUM_GAME_CARDS }
      end
    end

    context 'with 5 or 6 players' do
      let(:user_ids) { [1, 2, 3, 4, 5, 6] }

      it "deals #{Rummy::Implementation::BIG_GAME_CARDS} cards to each player" do
        game.start!
        players.each { |player| expect(player.cards.length).to eq Rummy::Implementation::BIG_GAME_CARDS }
      end
    end
  end

  describe '#draw_deck_turn' do
    let(:user_ids) { [1, 2] }
    let!(:game) { described_class.new(players, current_player_index: 0) }
    let(:top_card) { Card.new('5', 'Hearts') }
    let(:next_card) { Card.new('2', 'Diamonds') }

    before do
      game.start!
      game.deck.cards = [top_card, next_card]
    end

    it 'moves the top deck card into the current player’s hand' do
      game.draw_deck_turn
      expect(players.first.cards).to include top_card
      expect(game.deck.cards).to_not include top_card
    end

    it 'sets last_drawn_card to the drawn card' do
      game.draw_deck_turn
      expect(game.last_drawn_card).to eq top_card
    end

    it 'does not switch turns' do
      game.draw_deck_turn
      expect(game.current_player_index).to eq 0
    end

    it 'pushes one turn result to the feed' do
      game.draw_deck_turn
      expect(game.feed.length).to eq 1
    end

    it 'returns a turn result carrying the drawn card' do
      result = game.draw_deck_turn
      expect(result.current_user_id).to eq players.first.user_id
      expect(result.card_received_deck).to eq top_card
    end

    context 'when the player has already drawn this turn' do
      before { game.draw_deck_turn }

      it 'returns nil' do
        expect(game.draw_deck_turn).to be_nil
      end

      it 'does not draw a second card' do
        expect { game.draw_deck_turn }.to_not(change { players.first.cards.length })
      end
    end
  end

  describe '#start!' do
    context 'seeding the discard pile' do
      let(:user_ids) { [1, 2] }
      let(:cards_dealt_to_players) { user_ids.length * Rummy::Implementation::SMALL_GAME_CARDS }
      let(:top_of_deck) { Card.new('A', 'Spades') }
      let(:deck) { Deck.new(Array.new(cards_dealt_to_players, Card.new('2', 'Spades')) + [top_of_deck]) }
      let(:game) { described_class.new(players, deck: deck) }

      before { allow(deck).to receive(:shuffle) }

      it 'moves the top remaining deck card face-up onto the discard pile' do
        game.start!
        expect(game.discard_pile.cards).to eq [top_of_deck]
      end

      it 'removes that card from the deck' do
        expect { game.start! }.to change { deck.cards.length }.by(-(cards_dealt_to_players + 1))
        expect(deck.cards).to_not include top_of_deck
      end
    end
  end

  describe '#draw_discard_turn' do
    let(:user_ids) { [1, 2] }
    let!(:game) { described_class.new(players, current_player_index: 0) }
    let(:discard_top) { Card.new('5', 'Hearts') }

    before do
      game.start!
      game.discard_pile.cards = [discard_top]
    end

    it 'moves the top discard card into the current player’s hand' do
      game.draw_discard_turn
      expect(players.first.cards).to include discard_top
      expect(game.discard_pile.cards).to_not include discard_top
    end

    it 'sets last_drawn_card to the drawn card' do
      game.draw_discard_turn
      expect(game.last_drawn_card).to eq discard_top
    end

    it 'does not switch turns' do
      game.draw_discard_turn
      expect(game.current_player_index).to eq 0
    end

    it 'pushes one turn result to the feed' do
      game.draw_discard_turn
      expect(game.feed.length).to eq 1
    end

    it 'returns a turn result carrying the drawn card' do
      result = game.draw_discard_turn
      expect(result.current_user_id).to eq players.first.user_id
      expect(result.card_received_discard).to eq discard_top
    end

    context 'when the player has already drawn this turn' do
      before { game.draw_discard_turn }

      it 'returns nil' do
        expect(game.draw_discard_turn).to be_nil
      end
    end

    context 'when the discard pile is empty' do
      before { game.discard_pile.cards = [] }

      it 'returns nil' do
        expect(game.draw_discard_turn).to be_nil
      end
    end
  end

  describe '#last_drawn_card' do
    let(:user_ids) { [1, 2] }
    let!(:game) { described_class.new(players, current_player_index: 0) }
    let(:card) { Card.new('5', 'Hearts') }

    before { game.start! }

    context 'when the current player drew from the deck' do
      before { game.deck.cards = [card] }

      it 'returns the card drawn from the deck' do
        game.draw_deck_turn
        expect(game.last_drawn_card).to eq card
      end
    end

    context 'when the current player drew from the discard pile' do
      before { game.discard_pile.cards = [card] }

      it 'returns the card drawn from the discard pile' do
        game.draw_discard_turn
        expect(game.last_drawn_card).to eq card
      end
    end
  end

  describe '#drawn?' do
    let(:user_ids) { [1, 2] }
    let!(:game) { described_class.new(players, current_player_index: 0) }

    before { game.start! }

    context 'when the current player has not drawn a card' do
      it 'returns false' do
        expect(game.drawn?).to be false
      end
    end

    context 'when the current player has drawn a card' do
      before { game.draw_deck_turn }

      it 'returns true' do
        expect(game.drawn?).to be true
      end
    end
  end

  describe '#discardable_cards' do
    let(:hand_card) { Card.new('2', 'Clubs') }
    let(:drawn_card) { Card.new('5', 'Hearts') }
    let(:player1) { Rummy::Player.new(1) }
    let(:player2) { Rummy::Player.new(2) }
    let(:players) { [player1, player2] }
    let(:game) { described_class.new(players, deck: Deck.new([drawn_card]), current_player_index: 0) }

    before { game.draw_deck_turn }

    context 'when player has cards other than the picked up card' do
      before do
        player1.hand.cards = [hand_card, drawn_card]
      end

      it 'includes the cards already in hand' do
        expect(game.discardable_cards).to include hand_card
      end

      it 'excludes the just-drawn card' do
        expect(game.discardable_cards).to_not include drawn_card
      end
    end

    context 'when player only has the card picked up in hand' do
      before do
        player1.hand.cards = [drawn_card]
      end

      it 'includes the just-drawn card' do
        expect(game.discardable_cards).to eq [drawn_card]
      end
    end
  end

  describe '#discard_turn' do
    let(:hand_card) { Card.new('2', 'Clubs') }
    let(:drawn_card) { Card.new('5', 'Hearts') }
    let(:player1) { Rummy::Player.new(1, hand: CardCollection.new([hand_card])) }
    let(:player2) { Rummy::Player.new(2) }
    let(:players) { [player1, player2] }
    let(:game) { described_class.new(players, deck: Deck.new([drawn_card]), current_player_index: 0) }

    context 'when the current player has drawn a card' do
      before { game.draw_deck_turn }

      context 'when discarding a card in hand that was not just drawn' do
        it 'moves the card onto the discard pile' do
          game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)
          expect(game.discard_pile.cards).to include hand_card
        end

        it 'removes the card from the current player’s hand' do
          game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)
          expect(player1.cards).to_not include hand_card
        end

        it 'switches to the next player’s turn' do
          game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)
          expect(game.current_player_index).to eq 1
        end

        it 'resets last_drawn_card' do
          game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)
          expect(game.last_drawn_card).to be_nil
        end

        it 'pushes a turn result carrying the discarded card' do
          game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)
          expect(game.feed.last.card_discarded).to eq hand_card
        end
      end

      context 'when discarding the card that was just drawn' do
        it 'returns nil' do
          expect(game.discard_turn(rank: drawn_card.rank, suit: drawn_card.suit)).to be_nil
        end

        it 'does not push to the feed or switch turns' do
          expect { game.discard_turn(rank: drawn_card.rank, suit: drawn_card.suit) }
            .to_not(change { [game.feed.length, game.current_player_index] })
        end
      end

      context 'when discarding a card not in hand' do
        it 'returns nil' do
          expect(game.discard_turn(rank: 'K', suit: 'Clubs')).to be_nil
        end

        it 'does not push to the feed or switch turns' do
          expect { game.discard_turn(rank: 'K', suit: 'Clubs') }
            .to_not(change { [game.feed.length, game.current_player_index] })
        end
      end
    end

    context 'when the current player has not yet drawn' do
      it 'returns nil' do
        expect(game.discard_turn(rank: hand_card.rank, suit: hand_card.suit)).to be_nil
      end

      it 'does not push to the feed or switch turns' do
        expect { game.discard_turn(rank: hand_card.rank, suit: hand_card.suit) }
          .to_not(change { [game.feed.length, game.current_player_index] })
      end
    end
  end

  describe '#game_over?' do
    # TODO: implement a real test once the win condition (a player emptying their hand) is implemented
  end

  describe '#winning_player' do
    # TODO: implement a real test once the win condition (a player emptying their hand) is implemented
  end

  describe '#as_json, .from_json, and #==' do
    let(:user_ids) { [1, 2] }

    before { game.start! }

    it 'round-trips through dump and load' do
      restored = described_class.load(described_class.dump(game).as_json)
      expect(restored).to eq game
    end

    it 'is not equal when a field differs' do
      restored = described_class.load(described_class.dump(game).as_json)
      restored.switch_turn
      expect(restored).to_not eq game
    end

    it 'is not equal to nil' do
      expect(game).to_not eq(nil)
    end

    it 'round-trips the last_drawn_card' do
      game.draw_deck_turn
      restored = described_class.load(described_class.dump(game).as_json)
      expect(restored.last_drawn_card).to eq game.last_drawn_card
    end

    it 'is not equal when only last_drawn_card differs' do
      deck = Deck.new
      drawn = described_class.new(players, deck: deck, last_drawn_card: Card.new('5', 'Hearts'))
      not_drawn = described_class.new(players, deck: deck, last_drawn_card: nil)
      expect(drawn).to_not eq not_drawn
    end

    it 'round-trips the discard pile' do
      restored = described_class.load(described_class.dump(game).as_json)
      expect(restored.discard_pile).to eq game.discard_pile
    end

    it 'is not equal when only the discard pile differs' do
      deck = Deck.new
      seeded = described_class.new(players, deck: deck, discard_pile: Rummy::DiscardPile.new([Card.new('2', 'Clubs')]))
      empty = described_class.new(players, deck: deck, discard_pile: Rummy::DiscardPile.new)
      expect(seeded).to_not eq empty
    end
  end
end
