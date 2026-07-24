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
    let(:discard_top) { Rummy::Card.new('Q', 'Spades') }

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
        discarded_card = Rummy::Card.from_key(selected_value)

        click_on 'Discard and End Turn'

        within '.game-view__game-board' do
          expect(page).to have_css("img[src*='#{File.basename(discarded_card.to_image_name, '.*')}']")
        end
      end
    end
  end

  context 'laying a meld' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }
    let(:meld_cards) do
      [
        Rummy::Card.new('7', 'Spades'),
        Rummy::Card.new('7', 'Hearts'),
        Rummy::Card.new('7', 'Clubs')
      ]
    end

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      visit show_game_path(game)

      game.reload
      game.game_state.current_player.hand.cards = meld_cards.dup
      game.game_state.deck.cards -= meld_cards
      game.save!
      visit show_game_path(game)
      click_on 'Draw from Deck'
    end

    it 'shows a New Meld option and a checkbox for each card in hand' do
      game.reload
      hand_size = game.game_state.current_player.cards.length

      within('.game-view__game-feed') do
        expect(page).to have_select(options: ['New Meld'])
        expect(page.all('input[type="checkbox"]').count).to eq hand_size
      end
    end

    it 'lays a valid meld: cards leave the hand and the meld appears on the melds-board' do
      meld_cards.each { |card| check card.to_s }
      click_on 'Meld/Lay-off Selected'

      within('.game-view__hand') do
        meld_cards.each do |card|
          expect(page).to_not have_css("img[src*='#{File.basename(card.to_image_name, '.*')}']")
        end
      end

      within('.game-view__game-board') do
        expect(page).to have_content('Meld 1')
      end
    end

    it 'does not end the turn' do
      meld_cards.each { |card| check card.to_s }
      click_on 'Meld/Lay-off Selected'

      expect(page).to have_content('Your Turn')
    end

    it 'silently no-ops on an invalid selection' do
      check meld_cards.first.to_s
      click_on 'Meld/Lay-off Selected'

      within('.game-view__hand') do
        expect(page).to have_css("img[src*='#{File.basename(meld_cards.first.to_image_name, '.*')}']")
      end

      within('.game-view__game-board') do
        expect(page).to_not have_content('Meld 1')
      end
    end

    it 'shows the laid meld to the opponent' do
      meld_cards.each { |card| check card.to_s }
      click_on 'Meld/Lay-off Selected'

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)

      within('.game-view__game-board') do
        expect(page).to have_content('Meld 1')
      end
    end
  end

  context 'laying off onto a meld on the table' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }
    let(:meld) do
      Rummy::Meld.new([
                        Rummy::Card.new('7', 'Spades'),
                        Rummy::Card.new('7', 'Hearts'),
                        Rummy::Card.new('7', 'Clubs')
                      ])
    end
    let(:lay_off_card) { Rummy::Card.new('7', 'Diamonds') }

    before do
      create :game, :rummy, :with_users, name: game_name, player_count: 2, users: [user1, user2]
      visit show_game_path(game)

      game.reload
      game.game_state.current_player.hand.cards = [lay_off_card]
      game.game_state.deck.cards -= [lay_off_card] + meld.cards
      game.game_state.current_player.add_meld(meld)
      game.save!
      visit show_game_path(game)
      click_on 'Draw from Deck'
    end

    it 'extends the meld: the card leaves the hand and joins the meld on the board' do
      select "1: #{meld}", from: 'Meld'
      check lay_off_card.to_s
      click_on 'Meld/Lay-off Selected'

      within('.game-view__hand') do
        expect(page).to_not have_css("img[src*='#{File.basename(lay_off_card.to_image_name, '.*')}']")
      end
      within('.game-view__game-board') { expect(page).to have_content('4 cards') }
    end

    it 'does not end the turn' do
      select "1: #{meld}", from: 'Meld'
      check lay_off_card.to_s
      click_on 'Meld/Lay-off Selected'

      expect(page).to have_content('Your Turn')
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
