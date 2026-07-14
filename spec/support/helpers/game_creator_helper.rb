module GameCreatorHelper
  def create_game(name: 'Game', player_count: 2, game_type: 'Go Fish')
    visit new_game_path
    fill_in 'Name', with: name
    select game_type, from: 'Type'
    fill_in 'Player count', with: player_count
    click_button 'Create Game'
  end
end
