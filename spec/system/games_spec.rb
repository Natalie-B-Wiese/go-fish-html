require 'rails_helper'
RSpec.describe 'Games', type: :system do
  let(:user) {create(:user)}
  
  before do
    sign_in_as(user)
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

      it 'shows the new games in the games list' do
        create_game(name:'Cool game', player_count:2)
        create_game(name:'Cooler game', player_count:6)
        visit root_path
        expect(page).to have_content 'Cool game'
        expect(page).to have_content '1/2 Players'

        expect(page).to have_content 'Cooler game'
        expect(page).to have_content '1/6 Players'
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