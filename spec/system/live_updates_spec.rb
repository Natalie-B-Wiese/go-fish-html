require 'rails_helper'
RSpec.describe 'Live Updates in Game', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }

  let(:game_name) { 'Test Game' }
  let!(:factory_game) { create :started_game, name: game_name, player_count: 2, users: [user1, user2] }
  let(:game) { Game.find_by(name: game_name) }

  let(:p1_cards) { [Card.new('2', 'Diamonds'), Card.new('3', 'Hearts'), Card.new('4', 'Clubs')] }
  let(:p2_cards) { [Card.new('5', 'Hearts'), Card.new('6', 'Clubs')] }

  before do
    game.game_state.players[0].hand.cards = p1_cards.dup
    game.game_state.players[1].hand.cards = p2_cards.dup
    game.save!
    game.reload

    sign_in_as(user2)
    visit show_game_path(game)
  end

  context 'when a user plays a turn' do
    before do
      game.game_state.request_opponent_turn(opponent_user_id: user2.id, rank_requested: p1_cards.first.rank)
      game.save!
      game.reload
    end

    it 'automatically updates page for other players', :js do
      within '.feed-content' do
        expect(find_all('.feed-bubble').count).to_not eq 0
      end
    end

    it 'on turbo fetch, it does not show player 2 player 1\'s cards', :js do
      within '.game-view__hand' do
        p2_cards.each do |card|
          expect(page).to have_css("img[src*='#{File.basename(card.to_image_name, '.*')}']")
        end

        p1_cards.each do |card|
          expect(page).to have_no_css("img[src*='#{File.basename(card.to_image_name, '.*')}']")
        end
      end
    end
  end
end
