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
end
