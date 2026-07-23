require 'rails_helper'
RSpec.describe 'Rummy Games', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }

  before do
    sign_in_as(user1)
  end

  context 'show and start game flow' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      visit show_game_path(game)

      game.reload
      visit show_game_path(game)
    end

    it 'shows the game name' do
      expect(page).to have_content game_name
    end

    it 'deals a hand to the current player' do
      within '.game-view__hand' do
        expect(find_all('.playing-card').count).to eq Rummy::Implementation::SMALL_GAME_CARDS
      end
    end
  end

  context 'drawing from the deck' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      game.reload
      visit show_game_path(game)
    end

    it 'shows a Draw from Deck button on the current player’s turn' do
      expect(page).to have_button('Draw from Deck')
    end

    it 'moves the top deck card into the hand and hides the button' do
      hand_count = within('.game-view__hand') { find_all('.playing-card').count }

      click_on 'Draw from Deck'

      within('.game-view__hand') { expect(find_all('.playing-card').count).to eq(hand_count + 1) }
      expect(page).to_not have_button('Draw from Deck')
    end

    it 'keeps the button hidden after a page reload' do
      click_on 'Draw from Deck'

      visit show_game_path(game)

      expect(page).to_not have_button('Draw from Deck')
    end
  end
end
