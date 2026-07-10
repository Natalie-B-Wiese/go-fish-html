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
        expect(player1.cards.length).to eq CrazyEights::Implementation::SMALL_GAME_CARDS
        expect(player2.cards.length).to eq CrazyEights::Implementation::SMALL_GAME_CARDS
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
        expect(player1.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
        expect(player2.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
        expect(player3.cards.length).to eq CrazyEights::Implementation::BIG_GAME_CARDS
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
end
