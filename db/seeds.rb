# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
require 'bcrypt'

def create_user(email:, password:)
  password_digest=BCrypt::Password.create(password)
  user=User.find_by(email_address: email)

  if user
    user.password_digest = password_digest
    user.save!
  else
    user=User.create!(email_address: email, password: password, password_confirmation: password) 
  end
end

spiderman=create_user(email: 'spiderman@example.com', password: 'spiders_rock!')
batman=create_user(email: 'batman@example.com', password: 'batmobile')
joker=create_user(email: 'joker@example.com', password: 'batman')
ironman=create_user(email: 'ironman@example.com', password: 'stark')


# full started game
no_clowns_game=Game.find_or_create_by!(name: "No Clowns Allowed Game") do |game|
  game.player_count= 3
  game.started_at= DateTime.new(2026,6,3,1,1,5)
end

Player.find_or_create_by!(user: batman, game: no_clowns_game)
Player.find_or_create_by!(user: spiderman, game: no_clowns_game)
Player.find_or_create_by!(user: ironman, game: no_clowns_game)

# not full game (needs 2 more players)
villains_only=Game.find_or_create_by!(name: "Villains Only Game") do |game|
  game.player_count= 3
end
Player.find_or_create_by!(user: joker, game: villains_only)

# not full game (needs 1 more player)
everyone_game=Game.find_or_create_by!(name: "Everyone Game") do |game|
  game.player_count=4
end
Player.find_or_create_by!(user: spiderman, game: everyone_game)
Player.find_or_create_by!(user: batman, game: everyone_game)
Player.find_or_create_by!(user: ironman, game: everyone_game)
Player.find_or_create_by!(user: joker, game: everyone_game)

# full game that is finished where Batman wins
batman_wins_game=Game.find_or_create_by!(name: "Batman vs Joker Game") do |game|
  game.player_count=2
  game.started_at= DateTime.new(2001,2,2,1,1,5)
  game.ended_at= DateTime.new(2001,2,4,2,2,6)
end
batman_wins_game.save!

batman_win_player=Player.find_or_create_by!(user: batman, game: batman_wins_game)
Player.find_or_create_by!(user: joker, game: batman_wins_game)

batman_wins_game.winner_id=batman_win_player.id
batman_wins_game.save!