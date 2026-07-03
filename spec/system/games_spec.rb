require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let!(:user1) {create(:user1)}
  let!(:user2) {create(:user2)}
  let!(:user3) {create(:user3)}
  let!(:user4) {create(:user4)}
  
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
        create_game(name:'Game 1', player_count:2)
      end

      it 'creates a game and reroutes to that game\'s show path' do
        expect do
          create_game(name:'Game 1', player_count:2)
          expect(page).to have_current_path root_path
        end.to change(Game, :count).by 1
      end

      it 'creates a player and reroutes to root path' do
        expect do
          create_game(name:'Game 1', player_count:2)
        end.to change(Player, :count).by 1
      end

      it 'shows the new games in the my games list only' do
        create_game(name:'Cool game', player_count:2)
        create_game(name:'Cooler game', player_count:6)
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
    let(:game1_name) {'Cool game'}
    let!(:game) {create :game, :with_users, name: game1_name, player_count: 3, users: [user1]}
    

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
          expect(page.current_path).to eq show_game_path(game.id)
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
            expect(page.current_path).to eq show_game_path(game.id)
            
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
      let!(:game) {create :game, :with_users, name: game1_name, player_count: 3, users: [user1, user2, user3]}
      
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
          expect(page.current_path).to eq show_game_path(game.id)
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
    let(:game_name) {"Eddie's Game"}
    let(:game) {Game.find_by(name: game_name)}

    let(:full_game_name) {"Penelope's Game"}
    let(:full_game) {Game.find_by(name: full_game_name)}

    before do
      create :game, :with_users, name: game_name, player_count: 3, users: [user1, user2]
      create :game, :with_users, name: full_game_name, player_count: 3, users: [user1, user2, user3]
      visit show_game_path(game.id)
    end

    it 'shows the game name' do
      expect(page).to have_content game_name
    end
    
    it 'shows only the players in that game' do
      expect(page).to have_content user1.email_address
      expect(page).to have_content user2.email_address

      expect(page).to_not have_content user3.email_address
    end

    context 'before game is full' do
      it 'game is not started' do
        expect(game).to_not be_started
      end

      it 'shows waiting message' do
        expect(page).to have_content 'Waiting'
      end

      it 'does not show game started message' do
        expect(page).to_not have_content 'started'
      end
    end

    context 'when game is full' do
      before do
        visit show_game_path(full_game.id)
      end

      it 'starts the game and only starts it once' do
        expect(full_game.reload).to be_started
        started_at=Game.find(full_game.id).started_at

        sleep(1)
        visit show_game_path(full_game.id)
        expect(full_game.reload.started_at).to eq started_at
      end

      it 'shows game started message' do
        expect(page).to have_content 'started'
      end

      it 'does not show waiting message' do
        expect(page).to_not have_content 'Waiting'
      end
    end

  end

  context 'games page' do
    let!(:game1) {create :completed_game, :with_users_and_winner, name: 'Finished Game', users: [user1, user2], user_won: user2}

    it 'does not show games already finished' do
      visit games_path
      expect(page).to_not have_content 'Finished Game'
    end
  end

  context '/games/history' do
    let!(:game1) {create :completed_game, :with_users_and_winner, name: 'Game 1', users: [user1, user2], user_won: user2}
    let!(:game2) {create :completed_game, :with_users_and_winner, name: 'Game no user1', users: [user2, user3], user_won: user3}
    let!(:game3) {create :game, :with_users, name: 'Unfinished Game', users: [user1, user2, user3]}
    let!(:game4) {create :completed_game, :with_users_and_winner, name: 'Game 4', users: [user1, user3], user_won: user3}

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
      expect(page).to have_content user1.email_address+", "+user2.email_address
      expect(page).to have_content user1.email_address+", "+user3.email_address
    end

    it 'shows when it was finished' do
      expect(page).to have_content game1.ended_at.strftime("%b %d, %Y")
      expect(page).to have_content game4.ended_at.strftime("%b %d, %Y")
    end

    it 'show the winner' do
      expect(page).to have_content(user2.email_address).twice
      expect(page).to have_content(user3.email_address).twice
    end
  end
end