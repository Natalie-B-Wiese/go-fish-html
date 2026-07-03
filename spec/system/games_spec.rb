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

      it 'creates a game and reroutes to root path' do
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
    

    context 'when game does not have all players' do
      before do
        create :game, :with_users, name: game1_name, player_count: 3, users: [user1]
        visit games_path
      end
      
      it 'shows the players ratio' do
        expect(page).to have_content '1/3 Players'
      end
      
      context 'when player is already in game' do
        it 'it shows disabled waiting button' do
          expect(page).to have_button('Waiting for more players...', disabled: true)
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

        it 'allows player to join the game and returns to games page' do
          expect do
            click_on('Join')
            expect(page.current_path).to eq(games_path)
            
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
      
      before do
        create :game, :with_users, name: game1_name, player_count: 3, users: [user1, user2, user3]

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
    end


  end

  context '/games/history' do
    it 'shows the history' do
      visit games_history_path
      expect(page).to have_content 'History'
    end
  end
end