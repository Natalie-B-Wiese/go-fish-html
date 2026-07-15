require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }
  let!(:user4) { create(:user4) }

  before do
    sign_in_as(user1)
  end

  context 'games index' do
    let(:finished_game_name) { 'Finished Game' }
    let!(:finished_game) do
      create :completed_game, :with_users_and_winner, name: finished_game_name, users: [user1, user2], user_won: user2
    end

    let(:archived_game_name) { 'Archived Game' }
    let!(:archived_game) { create :game, :archived, :with_users, name: archived_game_name, users: [user1, user2] }

    before do
      visit games_path
    end

    it 'shows the games index' do
      expect(page.current_path).to eq games_path
      expect(page).to have_content 'Your Games'
      expect(page).to have_content 'All Games'
    end

    it 'does not show games already finished' do
      expect(page).to_not have_content finished_game_name
    end

    it 'does not show archived games' do
      expect(page).to_not have_content archived_game_name
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

  context 'games creation' do
    let(:game_name) { 'My First Game' }
    let(:capacity) { 2 }

    before do
      visit new_game_path
      fill_in 'Name', with: game_name
      select 'Go Fish', from: 'Type'
      fill_in 'Player count', with: capacity
    end

    it 'creates a game and a player' do
      expect do
        click_button 'Create Game'
      end.to change(Game, :count).by(1)
                                 .and change(Player, :count).by(1)
    end

    context 'after game is created and user goes to index page' do
      before do
        click_button 'Create Game'
        visit root_path
      end

      it 'shows the games in the correct section' do
        within('.my-games') { expect(page).to have_content game_name }
        within('.all-games') { expect(page).to_not have_content game_name }

        sign_out
        sign_in_as(user2)
        visit root_path
        within('.my-games') { expect(page).to_not have_content game_name }
        within('.all-games') { expect(page).to have_content game_name }
      end

      it 'shows correct button on game' do
        within('.my-games') { expect(page).to have_button('View') }

        sign_out
        sign_in_as(user2)
        visit root_path

        within('.all-games') { expect(page).to have_button('Join') }
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
        expect(full_game.reload).to be_started
        visit show_game_path(full_game)
      end

      it 'starts the game and only starts it once' do
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
    end
  end

  context '/games/history' do
    context 'when there are completed games' do
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
        expect(page).to have_css('table')
      end

      it 'shows only finished games belonging to user' do
        # the user right now is user 1
        expect(page).to have_content 'Game 1'
        expect(page).to have_content 'Game 4'

        expect(page).to_not have_content 'Game no user1'
        expect(page).to_not have_content 'Unfinished Game'
      end

      it 'shows who played' do
        expect(page).to have_content user1.name + ', ' + user2.name
        expect(page).to have_content user1.name + ', ' + user3.name
      end

      it 'shows when it was finished' do
        expect(page).to have_content game1.ended_at.strftime('%b %d, %Y')
        expect(page).to have_content game4.ended_at.strftime('%b %d, %Y')
      end

      it 'show the winner' do
        expect(page).to have_content(user2.name).twice
        expect(page).to have_content(user3.name).twice
      end
    end

    context 'when there are no completed games' do
      before do
        visit games_history_path
      end

      it 'does not show table' do
        expect(page).to_not have_css('table')
      end

      it 'shows a no games message' do
        expect(page).to have_content 'no'
      end
    end
  end

  def elements_within_parent(parent_selector:, element_index:, element_selector:)
    parent = page.find_all(parent_selector)[element_index]
    parent.find_all(element_selector)
    page.within parent do
      return page.find_all(element_selector, visible: :all)
    end
  end
end
