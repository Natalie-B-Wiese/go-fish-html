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
  password_digest = BCrypt::Password.create(password)
  user = User.find_by(email_address: email)

  if user
    user.password_digest = password_digest
    user.save!
  else
    user = User.create!(name: name, email_address: email, password: password, password_confirmation: password)
  end

  user
end

ironman = create_user(name: 'Tony Stark', email: 'ironman@example.com', password: 'stark')
spiderman = create_user(name: 'Peter Parker', email: 'spiderman@example.com', password: 'mj')
captain_america = create_user(name: 'Captain America', email: 'america@example.com', password: 'eagle')

spiderman_ironman_go_fish_game = Game.find_or_create_by!(name: 'Spiderman and Friends Go Fish') do |game|
  game.player_count = 2
  game.type = 'GoFishGame'
  game.started_at = '2026-07-10 14:09:05.988333'

  game.game_state = {
    deck: {
      cards: [
        {
          rank: '6',
          suit: 'Diamonds'
        },
        {
          rank: '10',
          suit: 'Hearts'
        },
        {
          rank: '2',
          suit: 'Diamonds'
        },
        {
          rank: '9',
          suit: 'Diamonds'
        },
        {
          rank: '7',
          suit: 'Clubs'
        },
        {
          rank: '3',
          suit: 'Hearts'
        },
        {
          rank: '7',
          suit: 'Spades'
        },
        {
          rank: 'J',
          suit: 'Hearts'
        },
        {
          rank: '10',
          suit: 'Diamonds'
        },
        {
          rank: 'A',
          suit: 'Spades'
        },
        {
          rank: '3',
          suit: 'Diamonds'
        },
        {
          rank: '7',
          suit: 'Hearts'
        },
        {
          rank: '2',
          suit: 'Clubs'
        },
        {
          rank: '6',
          suit: 'Spades'
        },
        {
          rank: '5',
          suit: 'Clubs'
        },
        {
          rank: 'A',
          suit: 'Clubs'
        },
        {
          rank: 'K',
          suit: 'Spades'
        },
        {
          rank: '4',
          suit: 'Spades'
        },
        {
          rank: '10',
          suit: 'Spades'
        },
        {
          rank: 'Q',
          suit: 'Hearts'
        },
        {
          rank: '8',
          suit: 'Diamonds'
        },
        {
          rank: '8',
          suit: 'Hearts'
        },
        {
          rank: '4',
          suit: 'Clubs'
        },
        {
          rank: 'J',
          suit: 'Spades'
        },
        {
          rank: '3',
          suit: 'Spades'
        },
        {
          rank: 'Q',
          suit: 'Clubs'
        },
        {
          rank: 'K',
          suit: 'Hearts'
        },
        {
          rank: '5',
          suit: 'Hearts'
        },
        {
          rank: 'J',
          suit: 'Clubs'
        },
        {
          rank: '7',
          suit: 'Diamonds'
        },
        {
          rank: '4',
          suit: 'Diamonds'
        },
        {
          rank: 'Q',
          suit: 'Spades'
        },
        {
          rank: '2',
          suit: 'Hearts'
        },
        {
          rank: 'A',
          suit: 'Diamonds'
        },
        {
          rank: '9',
          suit: 'Clubs'
        },
        {
          rank: '6',
          suit: 'Clubs'
        },
        {
          rank: 'Q',
          suit: 'Diamonds'
        },
        {
          rank: '9',
          suit: 'Spades'
        }
      ]
    },
    feed: [],
    players: [
      {
        hand: {
          cards: [
            {
              rank: '2',
              suit: 'Spades'
            },
            {
              rank: '3',
              suit: 'Clubs'
            },
            {
              rank: 'A',
              suit: 'Hearts'
            },
            {
              rank: '6',
              suit: 'Hearts'
            },
            {
              rank: 'J',
              suit: 'Diamonds'
            },
            {
              rank: '4',
              suit: 'Hearts'
            },
            {
              rank: 'K',
              suit: 'Clubs'
            }
          ]
        },
        books: [],
        user_id: spiderman.id
      },
      {
        hand: {
          cards: [
            {
              rank: '5',
              suit: 'Spades'
            },
            {
              rank: '8',
              suit: 'Spades'
            },
            {
              rank: '5',
              suit: 'Diamonds'
            },
            {
              rank: '9',
              suit: 'Hearts'
            },
            {
              rank: 'K',
              suit: 'Diamonds'
            },
            {
              rank: '8',
              suit: 'Clubs'
            },
            {
              rank: '10',
              suit: 'Clubs'
            }
          ]
        },
        books: [],
        user_id: ironman.id
      }
    ],
    current_player_index: 0
  }
end

Player.find_or_create_by!(user: spiderman, game: spiderman_ironman_go_fish_game)
Player.find_or_create_by!(user: ironman, game: spiderman_ironman_go_fish_game)

ironman_america_crazy_eights = Game.find_or_create_by!(name: 'Adults only Crazy Eights') do |game|
  game.player_count = 2
  game.type = 'CrazyEightsGame'
  game.started_at = '2026-07-13 13:49:50.492984'
  game.game_state = {
    deck: {
      cards: [
        {
          rank: '10',
          suit: 'Spades'
        },
        {
          rank: 'Q',
          suit: 'Clubs'
        },
        {
          rank: '7',
          suit: 'Hearts'
        },
        {
          rank: 'A',
          suit: 'Spades'
        },
        {
          rank: '8',
          suit: 'Diamonds'
        },
        {
          rank: '8',
          suit: 'Hearts'
        },
        {
          rank: '3',
          suit: 'Hearts'
        },
        {
          rank: '3',
          suit: 'Clubs'
        },
        {
          rank: '9',
          suit: 'Clubs'
        },
        {
          rank: '5',
          suit: 'Spades'
        },
        {
          rank: 'K',
          suit: 'Clubs'
        },
        {
          rank: 'A',
          suit: 'Diamonds'
        },
        {
          rank: '8',
          suit: 'Clubs'
        },
        {
          rank: '2',
          suit: 'Hearts'
        },
        {
          rank: '10',
          suit: 'Hearts'
        },
        {
          rank: '2',
          suit: 'Clubs'
        },
        {
          rank: '2',
          suit: 'Diamonds'
        },
        {
          rank: '10',
          suit: 'Clubs'
        },
        {
          rank: 'Q',
          suit: 'Diamonds'
        },
        {
          rank: '5',
          suit: 'Hearts'
        },
        {
          rank: 'Q',
          suit: 'Hearts'
        },
        {
          rank: 'A',
          suit: 'Hearts'
        },
        {
          rank: 'J',
          suit: 'Diamonds'
        },
        {
          rank: '4',
          suit: 'Hearts'
        },
        {
          rank: 'J',
          suit: 'Hearts'
        },
        {
          rank: '6',
          suit: 'Clubs'
        },
        {
          rank: '6',
          suit: 'Hearts'
        },
        {
          rank: '5',
          suit: 'Diamonds'
        },
        {
          rank: '3',
          suit: 'Spades'
        },
        {
          rank: 'K',
          suit: 'Spades'
        },
        {
          rank: '3',
          suit: 'Diamonds'
        },
        {
          rank: '6',
          suit: 'Diamonds'
        },
        {
          rank: '9',
          suit: 'Diamonds'
        },
        {
          rank: '4',
          suit: 'Spades'
        },
        {
          rank: '4',
          suit: 'Diamonds'
        },
        {
          rank: '5',
          suit: 'Clubs'
        },
        {
          rank: '10',
          suit: 'Diamonds'
        },
        {
          rank: 'Q',
          suit: 'Spades'
        },
        {
          rank: 'K',
          suit: 'Diamonds'
        },
        {
          rank: '7',
          suit: 'Diamonds'
        },
        {
          rank: 'A',
          suit: 'Clubs'
        }
      ]
    },
    feed: [
      {
        card_played: {
          rank: 'J',
          suit: 'Spades'
        },
        current_user_id: ironman.id,
        card_received_deck: nil
      }
    ],
    players: [
      {
        hand: {
          cards: [
            {
              rank: '6',
              suit: 'Spades'
            },
            {
              rank: 'J',
              suit: 'Clubs'
            },
            {
              rank: '7',
              suit: 'Spades'
            },
            {
              rank: '9',
              suit: 'Hearts'
            }
          ]
        },
        user_id: ironman.id
      },
      {
        hand: {
          cards: [
            {
              rank: '8',
              suit: 'Spades'
            },
            {
              rank: '4',
              suit: 'Clubs'
            },
            {
              rank: 'K',
              suit: 'Hearts'
            },
            {
              rank: '9',
              suit: 'Spades'
            },
            {
              rank: '7',
              suit: 'Clubs'
            }
          ]
        },
        user_id: captain_america.id
      }
    ],
    discard_pile: {
      cards: [
        {
          rank: 'J',
          suit: 'Spades'
        },
        {
          rank: '2',
          suit: 'Spades'
        }
      ]
    },
    current_player_index: 1
  }
end

Player.find_or_create_by!(user: ironman, game: ironman_america_crazy_eights)
Player.find_or_create_by!(user: captain_america, game: ironman_america_crazy_eights)

# an in progress 3 player game of Go Fish.
in_progress_go_fish_game = Game.find_or_create_by!(name: 'Everyone Go Fish Game') do |game|
  game.player_count = 3
  game.type = 'GoFishGame'
  game.started_at = '2026-07-13 14:49:57.697838'
  game.updated_at = '2026-07-13 15:00:25.452064'
  game.game_state = {
    deck: {
      cards: [
        {
          rank: 'A',
          suit: 'Hearts'
        },
        {
          rank: '7',
          suit: 'Diamonds'
        },
        {
          rank: '6',
          suit: 'Hearts'
        },
        {
          rank: 'J',
          suit: 'Spades'
        },
        {
          rank: '5',
          suit: 'Hearts'
        },
        {
          rank: '7',
          suit: 'Clubs'
        },
        {
          rank: '10',
          suit: 'Clubs'
        },
        {
          rank: '2',
          suit: 'Clubs'
        },
        {
          rank: '6',
          suit: 'Diamonds'
        },
        {
          rank: '5',
          suit: 'Spades'
        },
        {
          rank: '6',
          suit: 'Clubs'
        },
        {
          rank: 'J',
          suit: 'Hearts'
        },
        {
          rank: '8',
          suit: 'Diamonds'
        },
        {
          rank: 'K',
          suit: 'Spades'
        },
        {
          rank: 'A',
          suit: 'Spades'
        },
        {
          rank: 'J',
          suit: 'Diamonds'
        }
      ]
    },
    feed: [
      {
        was_book_made: false,
        rank_requested: '3',
        current_user_id: ironman.id,
        opponent_user_id: spiderman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '3',
            suit: 'Clubs'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '7',
        current_user_id: ironman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '8',
          suit: 'Hearts'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '8',
        current_user_id: spiderman.id,
        opponent_user_id: ironman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '8',
            suit: 'Hearts'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '8',
        current_user_id: spiderman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '10',
          suit: 'Diamonds'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '4',
        current_user_id: captain_america.id,
        opponent_user_id: spiderman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '4',
            suit: 'Diamonds'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: 'K',
        current_user_id: captain_america.id,
        opponent_user_id: spiderman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: 'K',
            suit: 'Diamonds'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '3',
        current_user_id: captain_america.id,
        opponent_user_id: ironman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '3',
            suit: 'Diamonds'
          },
          {
            rank: '3',
            suit: 'Clubs'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '9',
        current_user_id: captain_america.id,
        opponent_user_id: ironman.id,
        card_received_deck: {
          rank: '7',
          suit: 'Hearts'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: 'Q',
        current_user_id: ironman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: 'J',
          suit: 'Clubs'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '5',
        current_user_id: spiderman.id,
        opponent_user_id: ironman.id,
        card_received_deck: {
          rank: 'Q',
          suit: 'Hearts'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '9',
        current_user_id: captain_america.id,
        opponent_user_id: spiderman.id,
        card_received_deck: {
          rank: '10',
          suit: 'Spades'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: true,
        rank_requested: 'Q',
        current_user_id: ironman.id,
        opponent_user_id: spiderman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: 'Q',
            suit: 'Hearts'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '6',
        current_user_id: ironman.id,
        opponent_user_id: spiderman.id,
        card_received_deck: {
          rank: '10',
          suit: 'Hearts'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '10',
        current_user_id: spiderman.id,
        opponent_user_id: ironman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '10',
            suit: 'Hearts'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '10',
        current_user_id: spiderman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '10',
            suit: 'Spades'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: 'A',
        current_user_id: spiderman.id,
        opponent_user_id: ironman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: 'A',
            suit: 'Diamonds'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '8',
        current_user_id: spiderman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '3',
          suit: 'Spades'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '4',
        current_user_id: captain_america.id,
        opponent_user_id: ironman.id,
        card_received_deck: {
          rank: '9',
          suit: 'Diamonds'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: 'J',
        current_user_id: ironman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '2',
          suit: 'Diamonds'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '8',
        current_user_id: spiderman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '9',
          suit: 'Spades'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: true,
        rank_requested: '9',
        current_user_id: captain_america.id,
        opponent_user_id: spiderman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '9',
            suit: 'Spades'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: '7',
        current_user_id: captain_america.id,
        opponent_user_id: ironman.id,
        card_received_deck: nil,
        cards_received_opponent: [
          {
            rank: '7',
            suit: 'Spades'
          }
        ]
      },
      {
        was_book_made: false,
        rank_requested: 'K',
        current_user_id: captain_america.id,
        opponent_user_id: ironman.id,
        card_received_deck: {
          rank: '4',
          suit: 'Hearts'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: 'J',
        current_user_id: ironman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '2',
          suit: 'Spades'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: false,
        rank_requested: '10',
        current_user_id: spiderman.id,
        opponent_user_id: captain_america.id,
        card_received_deck: {
          rank: '5',
          suit: 'Clubs'
        },
        cards_received_opponent: []
      },
      {
        was_book_made: true,
        rank_requested: 'K',
        current_user_id: captain_america.id,
        opponent_user_id: spiderman.id,
        card_received_deck: {
          rank: '4',
          suit: 'Spades'
        },
        cards_received_opponent: []
      }
    ],
    players: [
      {
        hand: {
          cards: [
            {
              rank: '6',
              suit: 'Spades'
            },
            {
              rank: 'J',
              suit: 'Clubs'
            },
            {
              rank: '2',
              suit: 'Diamonds'
            },
            {
              rank: '2',
              suit: 'Spades'
            }
          ]
        },
        books: [
          {
            rank: 'Q'
          }
        ],
        user_id: ironman.id
      },
      {
        hand: {
          cards: [
            {
              rank: '8',
              suit: 'Spades'
            },
            {
              rank: '5',
              suit: 'Diamonds'
            },
            {
              rank: 'A',
              suit: 'Clubs'
            },
            {
              rank: '8',
              suit: 'Clubs'
            },
            {
              rank: '8',
              suit: 'Hearts'
            },
            {
              rank: '10',
              suit: 'Diamonds'
            },
            {
              rank: '10',
              suit: 'Hearts'
            },
            {
              rank: '10',
              suit: 'Spades'
            },
            {
              rank: 'A',
              suit: 'Diamonds'
            },
            {
              rank: '3',
              suit: 'Spades'
            },
            {
              rank: '5',
              suit: 'Clubs'
            }
          ]
        },
        books: [],
        user_id: spiderman.id
      },
      {
        hand: {
          cards: [
            {
              rank: '2',
              suit: 'Hearts'
            },
            {
              rank: '3',
              suit: 'Hearts'
            },
            {
              rank: 'K',
              suit: 'Hearts'
            },
            {
              rank: 'K',
              suit: 'Clubs'
            },
            {
              rank: 'K',
              suit: 'Diamonds'
            },
            {
              rank: '3',
              suit: 'Diamonds'
            },
            {
              rank: '3',
              suit: 'Clubs'
            },
            {
              rank: '7',
              suit: 'Hearts'
            },
            {
              rank: '7',
              suit: 'Spades'
            }
          ]
        },
        books: [
          {
            rank: '9'
          },
          {
            rank: '4'
          }
        ],
        user_id: captain_america.id
      }
    ],
    current_player_index: 0
  }
end
