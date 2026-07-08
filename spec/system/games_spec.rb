require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }
  let!(:user4) { create(:user4) }

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

  context 'games creation flow' do
    context 'when input is valid' do
      it 'allows user to fill out and submit form' do
        create_game(name: 'Game 1', player_count: 2)
      end

      it 'creates a game and reroutes to that game\'s show path' do
        expect do
          create_game(name: 'Game 1', player_count: 2)
          expect(page).to have_current_path root_path
        end.to change(Game, :count).by 1
      end

      it 'creates a player and reroutes to root path' do
        expect do
          create_game(name: 'Game 1', player_count: 2)
        end.to change(Player, :count).by 1
      end

      it 'shows the new games in the my games list only' do
        create_game(name: 'Cool game', player_count: 2)
        create_game(name: 'Cooler game', player_count: 6)
        visit root_path

        within('.my-games') do
          expect(page).to have_content 'Cool game'
          expect(page).to have_content '1/2 Players'

          expect(page).to have_content 'Cooler game'
          expect(page).to have_content '1/6 Players'
        end

        within('.all-games') do
          expect(page).to_not have_content 'Cool game'
          expect(page).to_not have_content '1/2 Players'

          expect(page).to_not have_content 'Cooler game'
          expect(page).to_not have_content '1/6 Players'
        end
      end
    end
  end

  context 'join game flow' do
    let(:game1_name) { 'Cool game' }
    let!(:game) { create :game, :with_users, name: game1_name, player_count: 3, users: [user1] }

    context 'when game does not have all players' do
      before do
        visit games_path
      end

      it 'shows the players ratio' do
        expect(page).to have_content '1/3 Players'
      end

      context 'when player is already in game' do
        it 'it shows view button' do
          expect(page).to have_button('View')
        end

        it 'clicking on button allows player to view the game' do
          click_on('View')
          expect(page.current_path).to eq show_game_path(game)
        end
      end

      context 'when player is not in the game' do
        before do
          sign_out
          sign_in_as(user2)
          visit games_path
        end

        it 'shows the game and a Join button inside all games panel only' do
          within('.all-games') do
            expect(page).to have_content game1_name
            expect(page).to have_button 'Join'
          end

          within('.my-games') do
            expect(page).to_not have_content game1_name
            expect(page).to_not have_button 'Join'
          end
        end

        it 'allows player to join the game and goes to show path' do
          expect do
            click_on('Join')
            expect(page.current_path).to eq show_game_path(game)

            visit root_path
            within('.all-games') do
              expect(page).to_not have_content '2/3 Players'
            end

            within('.my-games') do
              expect(page).to have_content '2/3 Players'
            end
          end.to change(Player, :count).by 1
        end
      end
    end

    context 'when game is full' do
      let!(:game) { create :game, :with_users, name: game1_name, player_count: 3, users: [user1, user2, user3] }

      before do
        sign_out
        sign_in_as(user3)
        visit games_path
      end

      it 'shows players ratio' do
        expect(page).to have_content '3/3 Players'
      end

      context 'when player is already in game' do
        it 'it shows enabled Play Now button' do
          expect(page).to have_button('Play Now')
        end

        it 'when clicked on play now, it allows player to view the game' do
          click_on 'Play Now'
          expect(page.current_path).to eq show_game_path(game)
        end
      end

      context 'when player is not in the game' do
        before do
          sign_out
          sign_in_as(user4)
          visit games_path
        end

        it 'does not show the game' do
          expect(page).to_not have_content game1_name
        end
      end
    end
  end

  context 'show and start game flow' do
    let(:unfull_game_name) { "Eddie's Game" }
    let(:unfull_game) { Game.find_by(name: unfull_game_name) }

    let(:full_game_name) { "Penelope's Game" }
    let(:full_game) { Game.find_by(name: full_game_name) }

    before do
      create :game, :with_users, name: unfull_game_name, player_count: 3, users: [user1, user2]
      create :game, :with_users, name: full_game_name, player_count: 3, users: [user1, user2, user3]
    end

    it 'shows the game name' do
      visit show_game_path(unfull_game)
      expect(page).to have_content unfull_game_name

      visit show_game_path(full_game)
      expect(page).to have_content full_game_name
    end

    it 'shows only the players in that game' do
      visit show_game_path(unfull_game)

      expect(page).to have_content user1.name
      expect(page).to have_content user2.name
      expect(page).to_not have_content user3.name
    end

    context 'before game is full' do
      before do
        visit show_game_path(unfull_game)
      end

      it 'game is not started' do
        expect(unfull_game).to_not be_started
      end

      it 'shows waiting message' do
        expect(page).to have_content 'Waiting'
      end

      # TODO: does not show other stuff
    end

    context 'when game is full' do
      before do
        visit show_game_path(full_game)
      end

      it 'starts the game and only starts it once' do
        expect(full_game.reload).to be_started
        started_at = Game.find(full_game.id).started_at

        sleep(1)
        visit show_game_path(full_game)
        expect(full_game.reload.started_at).to eq started_at
      end

      it 'does not have any feed bubbles in the feed' do
        within '.feed-content' do
          expect(find_all('.feed-bubble').count).to eq 0
        end
      end

      it 'does not show waiting message' do
        expect(page).to_not have_content 'Waiting'
      end

      context 'when game is started' do
        before do
          full_game.reload
          visit show_game_path(full_game)
        end

        it 'has accordions of other players only' do
          player1_accordions = elements_within_parent(parent_selector: '.players', element_index: 0,
                                                      element_selector: '.accordion')
          expect(player1_accordions[0]).to have_content(user2.name)
          expect(player1_accordions[1]).to have_content(user3.name)

          sign_out
          sign_in_as(user2)
          visit show_game_path(full_game)
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
          visit show_game_path(full_game)
          expect(page).to have_content("#{user1.name}'s Turn")
        end

        it 'enables Play button only for current player' do
          expect(page).to have_button('Play', disabled: false)

          sign_out
          sign_in_as(user2)
          visit show_game_path(full_game)
          expect(page).to have_button('Play', disabled: true)

          sign_out
          sign_in_as(user3)
          visit show_game_path(full_game)
          expect(page).to have_button('Play', disabled: true)
        end

        context 'when player has cards' do
          it 'has correct player dropdown options' do
            dropdown_options1 = page.find_field('Player').all('option').map(&:text)
            expect(dropdown_options1).to eq [user2.name, user3.name]

            sign_out
            sign_in_as(user2)
            visit show_game_path(full_game)

            dropdown_options2 = page.find_field('Player').all('option').map(&:text)
            expect(dropdown_options2).to eq [user1.name, user3.name]
          end

          it 'has correct rank dropdown options' do
            p1_card_ranks = full_game.go_fish.players[0].card_ranks
            dropdown_options1 = page.find_field('Rank').all('option').map(&:text)
            expect(dropdown_options1).to match_array(p1_card_ranks)

            sign_out
            sign_in_as(user2)
            visit show_game_path(full_game)
            p2_card_ranks = full_game.go_fish.players[1].card_ranks
            dropdown_options2 = page.find_field('Rank').all('option').map(&:text)
            expect(dropdown_options2).to match_array(p2_card_ranks)
          end

          context 'when current player clicks on play button' do
            before do
              page.click_on 'Play'
              full_game.reload
            end

            it 'stays on current game show page' do
              expect(page).to have_current_path show_game_path(full_game)
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
            full_game.go_fish.players.first.cards = []
            full_game.save!
            full_game.reload
            visit show_game_path(full_game)
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
              full_game.reload
            end

            it 'stays on current game show page' do
              expect(page).to have_current_path show_game_path(full_game)
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
              full_game.go_fish.deck.cards = []
              full_game.save!
              full_game.reload
              visit show_game_path(full_game)

              page.click_on 'Play'
              full_game.reload
            end

            it 'stays on current game show page' do
              expect(page).to have_current_path show_game_path(full_game)
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
              visit show_game_path(full_game)
              expect(page).to have_button('Play', disabled: false)
            end
          end
        end
      end

      context 'when game is over' do
        let(:winning_player) { full_game.go_fish.players.first }
        before do
          # ensures game is started
          full_game.reload
          visit show_game_path(full_game)

          # add the books
          add_books_to_player(full_game.go_fish.players.first, GoFish::Game::BOOKS_TO_WIN)
          full_game.save!

          full_game.reload
          visit show_game_path(full_game)
          full_game.reload
        end

        it 'records the winner' do
          expect(full_game.winner).to_not be_nil
          expect(full_game.winner.user_id).to eq winning_player.user_id
        end

        it 'records an ended at date only once' do
          ended_at = full_game.ended_at
          expect(ended_at).to_not be_nil

          sleep(3)

          full_game.reload
          visit show_game_path(full_game)
          full_game.reload
          expect(full_game.ended_at).to eq ended_at
        end

        it 'reroutes to history page' do
          expect(page.current_path).to eq games_history_path
        end
      end
    end
  end

  context 'games page' do
    let!(:game1) do
      create :completed_game, :with_users_and_winner, name: 'Finished Game', users: [user1, user2], user_won: user2
    end

    it 'does not show games already finished' do
      visit games_path
      expect(page).to_not have_content 'Finished Game'
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
end
