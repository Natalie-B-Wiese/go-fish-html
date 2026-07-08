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

def create_user(name:, email:, password:)
  password_digest=BCrypt::Password.create(password)
  user=User.find_by(email_address: email)

  if user
    user.password_digest = password_digest
    user.save!
  else
    user=User.create!(name: name, email_address: email, password: password, password_confirmation: password)
  end
end

spiderman=create_user(name: 'spiderman', email: 'spiderman@example.com', password: 'spiders_rock!')
batman=create_user(name: 'batman', email: 'batman@example.com', password: 'batmobile')
joker=create_user(name: 'joker', email: 'joker@example.com', password: 'batman')
ironman=create_user(name: 'iron man', email: 'ironman@example.com', password: 'stark')


# full started game
no_clowns_game=Game.find_or_create_by!(name: "No Clowns Allowed Game") do |game|
  game.player_count= 3
  game.started_at= DateTime.new(2026, 6, 3, 1, 1, 5)
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
  game.started_at= DateTime.new(2001, 2, 2, 1, 1, 5)
  game.ended_at= DateTime.new(2001, 2, 4, 2, 2, 6)
end
batman_wins_game.save!

batman_win_player=Player.find_or_create_by!(user: batman, game: batman_wins_game)
Player.find_or_create_by!(user: joker, game: batman_wins_game)

batman_wins_game.winner_id=batman_win_player.id
batman_wins_game.save!


spiderman_wins_game=Game.find_or_create_by!(name: "Cool Game") do |game|
  game.player_count=3
  game.started_at= DateTime.new(2020, 8, 20)
  game.ended_at= DateTime.new(2020, 8, 21)
end
spiderman_wins_game.save!

Player.find_or_create_by!(user: ironman, game: spiderman_wins_game)
spiderman_win_player=Player.find_or_create_by!(user: spiderman, game: spiderman_wins_game)
Player.find_or_create_by!(user: batman, game: spiderman_wins_game)

spiderman_wins_game.winner_id=spiderman_win_player.id
spiderman_wins_game.save!

large_finished_game=Game.find_or_create_by!(name: "Big Game") do |game|
  game.player_count=4
  game.started_at= DateTime.new(2018, 3, 2)
  game.ended_at= DateTime.new(2018, 4, 6)
end
large_finished_game.save!

Player.find_or_create_by!(user: ironman, game: large_finished_game)
Player.find_or_create_by!(user: spiderman, game: large_finished_game)
large_win_player=Player.find_or_create_by!(user: batman, game: large_finished_game)
Player.find_or_create_by!(user: joker, game: large_finished_game)

large_finished_game.winner_id=large_win_player.id
large_finished_game.save!
