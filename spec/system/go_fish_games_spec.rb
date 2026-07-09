require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }
  let!(:user4) { create(:user4) }

  before do
    sign_in_as(user1)
  end

  context 'games flow' do
    before do
      visit games_path
    end

    it 'shows the games index' do
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'All Games'
    end

    context 'when clicking the new game button' do
      before do
        click_on('New Game')
      end

      it 'shows the new game page' do
        expect(page).to have_content 'New Game'
        expect(page).to have_button 'Create Game'
        expect(page.current_path).to eq new_game_path
      end
    end
  end

  context 'show and start game flow' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :with_users, name: game_name, player_count: 3, users: [user1, user2, user3]
      visit show_game_path(game)

      game.reload
      visit show_game_path(game)
    end

    it 'shows the game name' do
      expect(page).to have_content game_name
    end

    it 'has accordions of other players only' do
      player1_accordions = elements_within_parent(parent_selector: '.players', element_index: 0,
                                                  element_selector: '.accordion')
      expect(player1_accordions[0]).to have_content(user2.name)
      expect(player1_accordions[1]).to have_content(user3.name)

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      player2_accordions = elements_within_parent(parent_selector: '.players', element_index: 0,
                                                  element_selector: '.accordion')
      expect(player2_accordions[0]).to have_content(user1.name)
      expect(player2_accordions[1]).to have_content(user3.name)
    end

    it 'deals the cards to the players' do
      within '.game-view__hand' do
        player1_card_count = find_all('.playing-card').count
        expect(player1_card_count).to eq GoFish::Game::SMALL_GAME_CARDS
      end

      player2_card_count = elements_within_parent(parent_selector: '.accordion',
                                                  element_index: 0, element_selector: '.playing-card').count
      player3_card_count = elements_within_parent(parent_selector: '.accordion',
                                                  element_index: 1, element_selector: '.playing-card').count

      expect(player2_card_count).to eq GoFish::Game::SMALL_GAME_CARDS
      expect(player3_card_count).to eq GoFish::Game::SMALL_GAME_CARDS
    end

    it 'shows whose turn it is' do
      expect(page).to have_content('Your Turn')

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      expect(page).to have_content("#{user1.name}'s Turn")
    end

    it 'enables Play button only for current player' do
      expect(page).to have_button('Play', disabled: false)

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      expect(page).to have_button('Play', disabled: true)

      sign_out
      sign_in_as(user3)
      visit show_game_path(game)
      expect(page).to have_button('Play', disabled: true)
    end

    context 'when non current player hacks in and clicks on play button', js: true do
      before do
        sign_out
        sign_in_as(user2)
        visit show_game_path(game)

        page.execute_script("document.querySelector(\"input[type='submit'][value='Play']\").disabled = false;")
        page.click_on 'Play'
        game.reload
      end

      it 'does not preform the move' do
        page.within '.feed-content' do
          expect(page.find_all('.feed-bubble').count).to eq 0
        end
      end
    end

    context 'when player has cards' do
      it 'has correct player dropdown options' do
        dropdown_options1 = page.find_field('Player').all('option').map(&:text)
        expect(dropdown_options1).to eq [user2.name, user3.name]

        sign_out
        sign_in_as(user2)
        visit show_game_path(game)

        dropdown_options2 = page.find_field('Player').all('option').map(&:text)
        expect(dropdown_options2).to eq [user1.name, user3.name]
      end

      it 'has correct rank dropdown options' do
        p1_card_ranks = game.game_state.players[0].card_ranks
        dropdown_options1 = page.find_field('Rank').all('option').map(&:text)
        expect(dropdown_options1).to match_array(p1_card_ranks)

        sign_out
        sign_in_as(user2)
        visit show_game_path(game)
        p2_card_ranks = game.game_state.players[1].card_ranks
        dropdown_options2 = page.find_field('Rank').all('option').map(&:text)
        expect(dropdown_options2).to match_array(p2_card_ranks)
      end

      context 'when current player clicks on play button' do
        before do
          page.click_on 'Play'
          game.reload
        end

        it 'stays on current game show page' do
          expect(page).to have_current_path show_game_path(game)
        end

        it 'preforms the move' do
          page.within '.game-view__hand' do
            expect(page.find_all('.playing-card').count).to_not eq GoFish::Game::SMALL_GAME_CARDS
          end
        end

        it 'posts 3 messages in the feed' do
          page.within '.feed-content' do
            expect(page.find_all('.feed-bubble').count).to eq 3
          end
        end
      end
    end

    context 'when current player is out of cards' do
      before do
        game.game_state.players.first.cards = []
        game.save!
        game.reload
        visit show_game_path(game)
      end

      it 'does not have dropdown for player' do
        expect(page).to_not have_select('Player')
      end

      it 'does not have dropdown for rank' do
        expect(page).to_not have_select('Rank')
      end

      context 'when current player clicks on play button and deck has cards' do
        before do
          page.click_on 'Play'
          game.reload
        end

        it 'stays on current game show page' do
          expect(page).to have_current_path show_game_path(game)
        end

        it 'draws from the deck' do
          page.within '.game-view__hand' do
            expect(page.find_all('.playing-card').count).to_not eq GoFish::Game::SMALL_GAME_CARDS
          end
        end

        it 'posts 2 messages in the feed' do
          page.within '.feed-content' do
            expect(page.find_all('.feed-bubble').count).to eq 2
          end
        end

        it 'allows player to go again' do
          expect(page).to have_button('Play', disabled: false)
        end
      end

      context 'when current player clicks on play button and deck has no cards' do
        before do
          game.game_state.deck.cards = []
          game.save!
          game.reload
          visit show_game_path(game)

          page.click_on 'Play'
          game.reload
        end

        it 'stays on current game show page' do
          expect(page).to have_current_path show_game_path(game)
        end

        it 'does not get a card' do
          page.within '.game-view__hand' do
            expect(page.find_all('.playing-card').count).to eq 0
          end
        end

        it 'posts 2 messages in the feed' do
          page.within '.feed-content' do
            expect(page.find_all('.feed-bubble').count).to eq 2
          end
        end

        it 'switches to next player' do
          expect(page).to have_button('Play', disabled: true)
          sign_out
          sign_in_as(user2)
          visit show_game_path(game)
          expect(page).to have_button('Play', disabled: false)
        end
      end
    end
  end

  context 'when game is over' do
    let(:winning_player) { game.game_state.players.first }

    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :with_users, name: game_name, player_count: 3, users: [user1, user2, user3]
      visit show_game_path(game)

      # ensures game is started
      game.reload
      visit show_game_path(game)

      # add the books
      add_books_to_player(game.game_state.players.first, GoFish::Game::BOOKS_TO_WIN)
      game.save!

      game.reload
      visit show_game_path(game)
      game.reload
    end

    it 'records the winner' do
      expect(game.winner).to_not be_nil
      expect(game.winner.user_id).to eq winning_player.user_id
    end

    it 'records an ended at date only once' do
      ended_at = game.ended_at
      expect(ended_at).to_not be_nil

      sleep(3)

      game.reload
      visit show_game_path(game)
      game.reload
      expect(game.ended_at).to eq ended_at
    end

    it 'reroutes to history page' do
      expect(page.current_path).to eq games_history_path
    end
  end

  context '/games/history' do
    let!(:game1) do
      create :completed_game, :with_users_and_winner, name: 'Game 1', users: [user1, user2], user_won: user2
    end
    let!(:game2) do
      create :completed_game, :with_users_and_winner, name: 'Game no user1', users: [user2, user3], user_won: user3
    end
    let!(:game3) { create :game, :with_users, name: 'Unfinished Game', users: [user1, user2, user3] }
    let!(:game4) do
      create :completed_game, :with_users_and_winner, name: 'Game 4', users: [user1, user3], user_won: user3
    end

    before do
      visit games_history_path
    end

    it 'shows the history' do
      expect(page).to have_content 'History'
      expect(page.current_path).to eq games_history_path
    end

    it 'shows only finished games belonging to user' do
      # the user right now is user 1
      expect(page).to have_content 'Game 1'
      expect(page).to have_content 'Game 4'

      expect(page).to_not have_content 'Game no user1'
      expect(page).to_not have_content 'Unfinished Game'
    end

    it 'shows who played' do
      expect(page).to have_content user1.email_address + ', ' + user2.email_address
      expect(page).to have_content user1.email_address + ', ' + user3.email_address
    end

    it 'shows when it was finished' do
      expect(page).to have_content game1.ended_at.strftime('%b %d, %Y')
      expect(page).to have_content game4.ended_at.strftime('%b %d, %Y')
    end

    it 'show the winner' do
      expect(page).to have_content(user2.email_address).twice
      expect(page).to have_content(user3.email_address).twice
    end
  end

  def elements_within_parent(parent_selector:, element_index:, element_selector:)
    parent = page.find_all(parent_selector)[element_index]
    parent.find_all(element_selector)
    page.within parent do
      return page.find_all(element_selector, visible: :all)
    end
  end

  def add_books_to_player(player, num_books = 1)
    num_books.times do
      player.books += [GoFish::Book.new('4')]
    end
  end
end
