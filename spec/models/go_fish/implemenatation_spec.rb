require 'rails_helper'

RSpec.describe GoFish::Implementation, type: :model do
  let!(:user1) { create :user1 }
  let!(:user2) { create :user2 }
  let!(:user3) { create :user3 }
  let!(:user4) { create :user4 }

  let!(:player1) { GoFish::Player.new(user1.id) }
  let!(:player2) { GoFish::Player.new(user2.id) }
  let!(:player3) { GoFish::Player.new(user3.id) }
  let!(:player4) { GoFish::Player.new(user4.id) }

  describe '#deal!' do
    context 'with 2 or 3 players' do
      let(:players) { [player1, player2] }
      let(:game) { described_class.new(players) }

      it "deals #{GoFish::Implementation::SMALL_GAME_CARDS} cards to each player" do
        game.deal!
        expect(player1.cards.length).to eq GoFish::Implementation::SMALL_GAME_CARDS
        expect(player2.cards.length).to eq GoFish::Implementation::SMALL_GAME_CARDS
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.deal!
      end
    end

    context 'with 4 or more players' do
      let(:players) { [player1, player2, player3, player4] }
      let(:game) { described_class.new(players) }

      before do
        game.deal!
      end

      it "deals #{GoFish::Implementation::BIG_GAME_CARDS} cards to each player" do
        expect(player1.cards.length).to eq GoFish::Implementation::BIG_GAME_CARDS
        expect(player2.cards.length).to eq GoFish::Implementation::BIG_GAME_CARDS
        expect(player3.cards.length).to eq GoFish::Implementation::BIG_GAME_CARDS
        expect(player4.cards.length).to eq GoFish::Implementation::BIG_GAME_CARDS
      end

      it 'cards are shuffled' do
        expect(game.deck).to receive(:shuffle)
        game.deal!
      end
    end
  end

  describe '#draw_deck_turn' do
    let!(:game) { described_class.new([player1, player2, player3], current_player_index: 0) }

    let(:card_taken) { Card.new('A', 'Spades') }
    let(:other_card) { Card.new('5', 'Spades') }

    let(:player1_index) { 0 }
    let(:player2_index) { 1 }

    context 'when player has no cards' do
      before do
        player1.hand.cards = []
      end

      it 'adds 1 turn result to the feed' do
        game.draw_deck_turn
        expect(game.feed.length).to eq 1
      end

      context 'deck is empty' do
        before do
          game.deck.cards = []
        end

        it 'returns the correct turn result' do
          result = game.draw_deck_turn
          expect(result.current_user_id).to eq player1.user_id
          expect(result.opponent_user_id).to be_nil
          expect(result.rank_requested).to be_nil
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to be_nil
          expect(result.was_book_made).to eq false
        end

        it 'switches turns' do
          game.draw_deck_turn
          expect(game.current_player_index).to eq player2_index
        end

        it 'adds 1 turn result to the feed' do
          game.draw_deck_turn
          expect(game.feed.length).to eq 1
        end
      end

      context 'deck has cards' do
        before do
          game.deck.cards = [card_taken, other_card]
        end

        it 'removes the card from the top of the deck' do
          game.draw_deck_turn
          expect(game.deck.cards).to_not include card_taken
          expect(game.deck.cards).to include other_card
        end

        it 'gives the card to the player' do
          game.draw_deck_turn
          expect(player1.cards).to include card_taken
          expect(player1.cards).to_not include other_card
        end

        it 'returns the correct turn result' do
          result = game.draw_deck_turn
          expect(result.current_user_id).to eq player1.user_id
          expect(result.opponent_user_id).to be_nil
          expect(result.rank_requested).to be_nil
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to eq card_taken
          expect(result.was_book_made).to eq false
        end

        it 'does not switch turns' do
          game.draw_deck_turn
          expect(game.current_player_index).to eq player1_index
        end
      end

      it 'works with other players' do
        game.deck.cards = [card_taken, other_card]
        game.current_player_index = 1

        result = game.draw_deck_turn
        expect(result.current_user_id).to eq player2.user_id

        expect(game.deck.cards).to_not include card_taken
        expect(player2.cards).to include card_taken
        expect(game.current_player_index).to eq player2_index
      end
    end

    context 'when player has cards' do
      before do
        player1.hand.cards = [Card.new('2', 'Diamonds')]
      end

      it 'does not add a turn result to the feed' do
        game.draw_deck_turn
        expect(game.feed).to be_empty
      end

      it 'does not preform the move' do
        card_count_before = player1.cards.length
        game.draw_deck_turn
        expect(player1.cards.length).to eq card_count_before
      end

      it 'does not switch turns' do
        game.draw_deck_turn
        expect(game.current_player_index).to eq player1_index
      end

      it 'returns nil' do
        expect(game.draw_deck_turn).to be_nil
      end
    end
  end

  describe '#request_opponent_turn' do
    let!(:game) { described_class.new([player1, player2, player3], current_player_index: 0) }

    let!(:rank_have) { '5' }
    let!(:invalid_rank) { 'A' }
    let(:player1_index) { 0 }

    before do
      player1.hand.cards = [Card.new(rank_have, 'Diamonds')]
    end

    context 'when player does not have the rank' do
      it 'returns nil and does nothing' do
        card_count_before = player1.cards.length
        result = game.request_opponent_turn(opponent_user_id: player2.user_id, rank_requested: invalid_rank)

        expect(result).to be_nil
        expect(game.feed).to be_empty
        expect(player1.cards.length).to eq card_count_before
        expect(game.current_player_index).to eq player1_index
      end
    end

    context 'when player has the rank and opponent is self' do
      it 'returns nil and does nothing' do
        self_user_id = player1.user_id
        card_count_before = player1.cards.length
        result = game.request_opponent_turn(opponent_user_id: self_user_id, rank_requested: rank_have)

        expect(result).to be_nil
        expect(game.feed).to be_empty
        expect(player1.cards.length).to eq card_count_before
        expect(game.current_player_index).to eq player1_index
      end
    end

    context 'when player has the rank and opponent does not exist in game' do
      it 'returns nil and does nothing' do
        nonexistant_opponent_id = player4.user_id
        card_count_before = player1.cards.length
        result = game.request_opponent_turn(opponent_user_id: nonexistant_opponent_id, rank_requested: rank_have)

        expect(result).to be_nil
        expect(game.feed).to be_empty
        expect(player1.cards.length).to eq card_count_before
        expect(game.current_player_index).to eq player1_index
      end
    end

    context 'when player has the rank and opponent is valid' do
      it 'adds 1 turn result to the feed' do
        game.request_opponent_turn(opponent_user_id: player3.user_id, rank_requested: '5')
        expect(game.feed.length).to eq 1
      end

      context 'when opponent has that card' do
        before do
          player1.hand.cards = [Card.new('5', 'Hearts')]
          player3.hand.cards = [Card.new('5', 'Diamonds')]
        end
        context 'when opponent has 1 match' do
          let(:rank) { '5' }
          let(:opponent) { player3 }
          let(:taken_card) { Card.new(rank, 'Diamonds') }
          it 'takes from opponent and gives to player' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.cards).to include taken_card
            expect(opponent.cards).to_not include taken_card
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to eq [taken_card]
            expect(result.card_received_deck).to be_nil
            expect(result.was_book_made).to eq false
            expect(result.go_again?).to eq true
          end

          it 'does not switch turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player_index).to eq 0
          end
        end

        context 'when opponent has more than one match' do
          before do
            player1.hand.cards = [Card.new('A', 'Spades')]
            player2.hand.cards = [Card.new('A', 'Hearts'), Card.new('A', 'Clubs')]
          end

          let(:rank) { 'A' }
          let(:opponent) { player2 }
          let!(:taken_card1) { opponent.cards[0] }
          let!(:taken_card2) { opponent.cards[1] }

          it 'takes from opponent and gives to player' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.cards).to include taken_card1
            expect(player1.cards).to include taken_card2

            expect(opponent.cards).to_not include taken_card1
            expect(opponent.cards).to_not include taken_card2
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to eq [taken_card1, taken_card2]
            expect(result.card_received_deck).to be_nil
            expect(result.was_book_made).to eq false
            expect(result.go_again?).to eq true
          end

          it 'does not switch turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player_index).to eq 0
          end
        end

        context 'when player can make a book' do
          let(:rank) { 'A' }

          before do
            player1.hand.cards = [Card.new(rank, 'Spades'), Card.new(rank, 'Hearts')]
            player2.hand.cards = [Card.new(rank, 'Diamonds'), Card.new(rank, 'Clubs')]
          end

          let(:opponent) { player2 }
          let!(:card1) { player1.cards[0] }
          let!(:card2) { player1.cards[1] }
          let!(:card3) { player2.cards[0] }
          let!(:card4) { player2.cards[1] }

          it 'takes from both opponent and player' do
            game.request_opponent_turn(rank_requested: rank, opponent_user_id: opponent.user_id)
            expect(player1.cards).to_not include card1
            expect(player1.cards).to_not include card2
            expect(player1.cards).to_not include card3
            expect(player1.cards).to_not include card4

            expect(opponent.cards).to_not include card1
            expect(opponent.cards).to_not include card2
            expect(opponent.cards).to_not include card3
            expect(opponent.cards).to_not include card4
          end

          it 'makes a book' do
            game.request_opponent_turn(rank_requested: rank, opponent_user_id: opponent.user_id)
            expect(player1.book_count).to eq 1
            expect(opponent.book_count).to eq 0
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(rank_requested: rank, opponent_user_id: opponent.user_id)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to eq [card3, card4]
            expect(result.card_received_deck).to be_nil
            expect(result.was_book_made).to eq true
            expect(result.go_again?).to eq true
          end

          it 'does not switch turns' do
            game.request_opponent_turn(rank_requested: rank, opponent_user_id: opponent.user_id)
            expect(game.current_player).to eq player1
          end
        end
      end

      context 'when go fish and success' do
        let(:opponent) { player2 }
        let(:taken_card) { Card.new(rank, 'Spades') }

        before do
          opponent.hand.cards = [Card.new('8', 'Diamonds')]
        end

        context 'when player cannot make book' do
          let(:rank) { 'A' }

          before do
            game.deck.cards = [taken_card, Card.new('5', 'Clubs')]
            player1.hand.cards = [Card.new(rank, 'Hearts')]
          end

          it 'takes from top of deck and gives to player' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.cards).to include taken_card
            expect(game.deck.cards).to_not include taken_card
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)

            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to be_empty
            expect(result.card_received_deck).to eq taken_card
            expect(result.was_book_made).to eq false
            expect(result.go_again?).to eq true
          end

          it 'does not switch turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player).to eq player1
          end
        end

        context 'when player can make a book' do
          let(:rank) { 'A' }

          before do
            player1.hand.cards = [Card.new(rank, 'Spades'), Card.new(rank, 'Hearts'), Card.new(rank, 'Diamonds')]
            game.deck.cards = [taken_card]
          end

          it 'makes a book' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.book_count).to eq 1
            expect(opponent.book_count).to eq 0
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to be_empty
            expect(result.card_received_deck).to eq taken_card
            expect(result.was_book_made).to eq true
            expect(result.go_again?).to eq true
          end

          it 'does not switch turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player).to eq player1
          end
        end
      end

      context 'when go fish and fail' do
        let(:opponent) { player2 }
        let(:other_rank) { '5' }
        let(:rank) { 'A' }

        let(:taken_card) { Card.new(other_rank, 'Spades') }

        before do
          opponent.hand.cards = [Card.new('8', 'Diamonds')]
        end

        context 'when player cannot make book' do
          before do
            game.deck.cards = [taken_card]
            player1.hand.cards = [Card.new(rank, 'Hearts')]
          end

          it 'takes from top of deck and gives to player' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.cards).to include taken_card
            expect(game.deck.cards).to_not include taken_card
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to be_empty
            expect(result.card_received_deck).to eq taken_card
            expect(result.was_book_made).to eq false
            expect(result.go_again?).to eq false
          end

          it 'switches turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player).to eq player2
          end
        end

        context 'when player can make a book' do
          let(:rank) { 'A' }
          let(:taken_card) { Card.new(other_rank, 'Clubs') }

          before do
            player1.hand.cards = [Card.new(rank, 'Hearts'), Card.new(other_rank, 'Spades'),
                                  Card.new(other_rank, 'Hearts'), Card.new(other_rank, 'Diamonds')]
            game.deck.cards = [taken_card]
          end

          it 'makes a book' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(player1.book_count).to eq 1
            expect(opponent.book_count).to eq 0
          end

          it 'returns the correct turn result' do
            result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(result.current_user_id).to eq player1.user_id
            expect(result.opponent_user_id).to eq opponent.user_id
            expect(result.rank_requested).to eq rank
            expect(result.cards_received_opponent).to be_empty
            expect(result.card_received_deck).to eq taken_card
            expect(result.was_book_made).to eq true
            expect(result.go_again?).to eq false
          end

          it 'switches turns' do
            game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
            expect(game.current_player).to_not eq player1
          end
        end
      end

      context 'when go fish and deck empty' do
        let(:opponent) { player2 }
        let(:rank) { 'A' }

        before do
          opponent.hand.cards = [Card.new('8', 'Diamonds')]
          player1.hand.cards = [Card.new(rank, 'Hearts')]
          game.deck.cards = []
        end
        it 'returns the correct turn result' do
          result = game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
          expect(result.current_user_id).to eq player1.user_id
          expect(result.opponent_user_id).to eq opponent.user_id
          expect(result.rank_requested).to eq rank
          expect(result.cards_received_opponent).to be_empty
          expect(result.card_received_deck).to be_nil
          expect(result.was_book_made).to eq false
          expect(result.go_again?).to eq false
        end

        it 'switches turns' do
          game.request_opponent_turn(opponent_user_id: opponent.user_id, rank_requested: rank)
          expect(game.current_player).to eq player2
        end
      end
    end
  end

  describe '#winning_player' do
    let(:players) { [player1, player2, player3] }
    let(:game) { described_class.new(players) }

    context 'when one player has most books' do
      before do
        player1.books = []
        player2.books = [GoFish::Book.new('5'), GoFish::Book.new('2'), GoFish::Book.new('10')]
        player3.books = [GoFish::Book.new('A')]
      end

      it 'returns that player' do
        result = game.winning_player

        expect(result).to eq player2
      end
    end

    context 'when there is a tie' do
      before do
        player1.books = [GoFish::Book.new('8'), GoFish::Book.new('5'), GoFish::Book.new('2')]
        player2.books = [GoFish::Book.new('5'), GoFish::Book.new('3'), GoFish::Book.new('4')]
        player3.books = [GoFish::Book.new('A')]
      end

      it 'returns user with most book and highest value book' do
        result = game.winning_player
        expect(result).to eq player1
      end
    end
  end

  describe '#game_over?' do
    let!(:game) { described_class.new([player1, player2]) }
    # def game_over?
    #   book_count == BOOKS_TO_WIN
    # end
    context 'when not all books have been won' do
      before do
        add_books_to_player(player1, 5)
        add_books_to_player(player2, 3)
      end

      it 'returns false' do
        expect(game).to_not be_game_over
      end
    end

    context 'when all books have been won' do
      let(:p1_books) { 5 }
      before do
        add_books_to_player(player1, p1_books)
        add_books_to_player(player2, GoFish::Implementation::BOOKS_TO_WIN - p1_books)
      end

      it 'returns true' do
        expect(game).to be_game_over
      end
    end
  end

  def add_books_to_player(player, num_books = 1)
    num_books.times do
      player.books += [GoFish::Book.new('4')]
    end
  end
end
