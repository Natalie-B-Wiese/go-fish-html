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

  context 'taking from the discard pile' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      game.reload
      visit show_game_path(game)
    end

    it 'shows a Take from Discard button on the current player’s turn' do
      expect(page).to have_button('Take from Discard')
    end

    it 'moves the top discard card into the hand and hides both draw buttons' do
      hand_count = within('.game-view__hand') { find_all('.playing-card').count }

      click_on 'Take from Discard'

      within('.game-view__hand') { expect(find_all('.playing-card').count).to eq(hand_count + 1) }
      expect(page).to_not have_button('Take from Discard')
      expect(page).to_not have_button('Draw from Deck')
    end

    it 'removes the top card from the discard pile' do
      expect(page).to have_content('1 cards')

      click_on 'Take from Discard'

      expect(page).to have_content('0 cards')
    end

    it 'keeps the button hidden after a page reload' do
      click_on 'Take from Discard'

      visit show_game_path(game)

      expect(page).to_not have_button('Take from Discard')
    end
  end

  context 'showing the discard pile on the board' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }
    let(:discard_top) { Card.new('Q', 'Spades') }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      visit show_game_path(game)

      game.reload
      game.game_state.discard_pile.cards = [discard_top]
      game.save!
      visit show_game_path(game)
    end

    it 'shows the top discard card’s image' do
      within '.game-view__game-board' do
        expect(page).to have_css("img[src*='#{File.basename(discard_top.to_image_name, '.*')}']")
      end
    end
  end

  context 'discarding and ending the turn' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      game.reload
      visit show_game_path(game)
    end

    context 'when the player has not drawn a card' do
      it 'hides the Discard and End Turn button' do
        expect(page).to_not have_button('Discard and End Turn')
      end
    end

    context 'when the player has drawn a card' do
      before do
        click_on 'Draw from Deck'
      end

      it 'ends the turn when the current player discards a card' do
        click_on 'Discard and End Turn'

        expect(page).to have_content("#{user2.name}'s Turn")
      end

      it 'has correct card dropdown options and values' do
        game.reload
        card_options = game.game_state.discardable_cards

        dropdown_options = page.find_field('Card').all('option')

        dropdown_labels = dropdown_options.map(&:text)
        dropdown_values = dropdown_options.map { |opt| opt[:value] }

        expect(dropdown_labels).to match_array(CardCollection.cards_to_h(card_options).keys)
        expect(dropdown_values).to match_array(CardCollection.cards_to_h(card_options).values)
      end

      it 'shows the discarded card’s image on the discard pile' do
        selected_value = page.find_field('Card').all('option').first[:value]
        discarded_card = Card.from_key(selected_value)

        click_on 'Discard and End Turn'

        within '.game-view__game-board' do
          expect(page).to have_css("img[src*='#{File.basename(discarded_card.to_image_name, '.*')}']")
        end
      end
    end
  end

  context 'showing the deck on the board' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      visit show_game_path(game)

      game.reload
      visit show_game_path(game)
    end

    it 'shows the current number of cards left in the deck' do
      within '.game-view__game-board' do
        expect(page).to have_content("#{game.game_state.deck.card_count} cards")
      end
    end
  end
end
