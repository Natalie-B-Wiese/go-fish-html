require 'rails_helper'
RSpec.describe 'Crazy Eights Games', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }
  let!(:user4) { create(:user4) }

  before do
    sign_in_as(user1)
  end

  context 'show and start game flow' do
    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :crazy_eights, :with_users, name: game_name, player_count: 3, users: [user1, user2, user3]
      visit show_game_path(game)

      game.reload
      visit show_game_path(game)
    end

    it 'shows the game name' do
      expect(page).to have_content game_name
    end

    it 'has accordions of other players only' do
      player1_accordions = elements_within_parent(parent_selector: '.players', element_index: 0,
                                                  element_selector: '.accordion')
      expect(player1_accordions[0]).to have_content(user2.name)
      expect(player1_accordions[1]).to have_content(user3.name)

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      player2_accordions = elements_within_parent(parent_selector: '.players', element_index: 0,
                                                  element_selector: '.accordion')
      expect(player2_accordions[0]).to have_content(user1.name)
      expect(player2_accordions[1]).to have_content(user3.name)
    end

    it 'deals the cards to the players' do
      within '.game-view__hand' do
        player1_card_count = find_all('.playing-card').count
        expect(player1_card_count).to_not eq 0
      end

      player2_card_count = elements_within_parent(parent_selector: '.accordion',
                                                  element_index: 0, element_selector: '.playing-card').count
      player3_card_count = elements_within_parent(parent_selector: '.accordion',
                                                  element_index: 1, element_selector: '.playing-card').count

      expect(player2_card_count).to_not eq 0
      expect(player3_card_count).to_not eq 0
    end

    it 'shows whose turn it is' do
      expect(page).to have_content('Your Turn')

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      expect(page).to have_content("#{user1.name}'s Turn")
    end

    it 'enables Play button only for current player' do
      expect(page).to have_button('Play', disabled: false)

      sign_out
      sign_in_as(user2)
      visit show_game_path(game)
      expect(page).to have_button('Play', disabled: true)

      sign_out
      sign_in_as(user3)
      visit show_game_path(game)
      expect(page).to have_button('Play', disabled: true)
    end

    context 'when non current player hacks in and clicks on play button', js: true do
      before do
        sign_out
        sign_in_as(user2)
        visit show_game_path(game)

        page.execute_script("document.querySelector(\"input[type='submit'][value='Play']\").disabled = false;")
        page.click_on 'Play'
        game.reload
      end

      it 'does not preform the move' do
        page.within '.feed-content' do
          expect(page.find_all('.feed-bubble').count).to eq 0
        end
      end
    end

    context 'when current player has card to play' do
      let(:player) { game.game_state.players.first }
      let(:discard_card) { player.cards.first }
      before do
        game.game_state.discard_pile.insert_card_to_top(discard_card)
        game.save!
        game.reload

        visit show_game_path(game)
      end

      it 'has correct rank dropdown options and values' do
        card_options = player.playable_cards(discard_card)

        dropdown_options = page.find_field('Card').all('option')

        dropdown_labels = dropdown_options.map(&:text)
        dropdown_values = dropdown_options.map { |opt| opt[:value] }

        expect(dropdown_labels).to match_array(player.cards_to_h(card_options).keys)
        expect(dropdown_values).to match_array(player.cards_to_h(card_options).values)
      end

      context 'when current user clicks on play button' do
        let!(:card_count_before) do
          page.within('.game-view__hand') do
            page.all('.playing-card').count
          end
        end

        before do
          page.click_on 'Play'
          game.reload
        end

        it 'stays on current game show page' do
          expect(page).to have_current_path show_game_path(game)
        end

        it 'preforms the move' do
          page.within '.game-view__hand' do
            expect(page.find_all('.playing-card').count).to_not eq card_count_before
          end
        end

        it 'posts messages in the feed' do
          visit show_game_path(game)

          page.within '.feed-content' do
            expect(page.find_all('.feed-bubble').count).to_not eq 0
          end
        end
      end
    end

    context 'when current player has no playable cards' do
      before do
        game.game_state.players.first.cards = [Card.new('5', 'Hearts')]
        game.game_state.discard_pile.insert_card_to_top(Card.new('3', 'Diamonds'))

        game.save!
        game.reload

        visit show_game_path(game)
      end

      it 'does not have dropdown for card' do
        expect(page).to_not have_select('Card')
      end

      context 'when current player clicks on play button' do
        let!(:card_count_before) { game.game_state.players.first.cards.length }

        before do
          page.click_on 'Play'
          game.reload
        end

        it 'stays on current game show page and draws a card from the deck' do
          expect(page).to have_current_path show_game_path(game)
        end

        it 'draws from the deck' do
          page.within '.game-view__hand' do
            expect(page.find_all('.playing-card').count).to eq(card_count_before + 1)
          end
        end

        it 'posts messages in the feed' do
          page.within '.feed-content' do
            expect(page.find_all('.feed-bubble').count).to_not eq 0
          end
        end

        it 'allows player to go again' do
          expect(page).to have_button('Play', disabled: false)
        end
      end
    end
  end

  xcontext 'when game is over' do
    let(:winning_player) { game.game_state.players.first }

    let(:game_name) { "Penelope's Game" }
    let(:game) { Game.find_by(name: game_name) }

    before do
      create :game, :crazy_eights, :with_users, name: game_name, player_count: 3, users: [user1, user2, user3]
      visit show_game_path(game)

      # ensures game is started
      game.reload
      visit show_game_path(game)

      # force the win condition
      game.game_state.players.first.cards = []
      game.save!

      game.reload
      visit show_game_path(game)
      game.reload
    end

    it 'records the winner' do
      expect(game.winner).to_not be_nil
      expect(game.winner.user_id).to eq winning_player.user_id
    end

    it 'records an ended at date only once' do
      ended_at = game.ended_at
      expect(ended_at).to_not be_nil

      sleep(3)

      game.reload
      visit show_game_path(game)
      game.reload
      expect(game.ended_at).to eq ended_at
    end

    it 'reroutes to history page' do
      expect(page.current_path).to eq games_history_path
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
