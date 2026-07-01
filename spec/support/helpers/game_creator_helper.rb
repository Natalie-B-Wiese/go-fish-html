
module GameCreatorHelper
  def create_game(name:'Game', player_count:2)
    visit new_game_path
    fill_in "Name", with: name
    # fill_in "Game type", with: game_type
    fill_in "Player count", with: player_count
    click_button 'Create Game'
  end
end
