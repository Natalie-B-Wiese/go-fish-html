FactoryBot.define do
  factory :game do
    name { 'Game 1' }
    player_count { 2 }
    started_at { nil }
    ended_at { nil }
    updated_at { Time.zone.now }
    type { 'GoFishGame' }
    association :winner, factory: :player, strategy: :null
    archived_at { nil }

    trait :go_fish do
      type { 'GoFishGame' }
    end

    trait :crazy_eights do
      type { 'CrazyEightsGame' }
    end

    trait :started do
      started_at { Time.zone.now }
    end

    trait :completed do
      ended_at { Time.zone.now }
    end

    trait :archived do
      archived_at { Time.zone.now }
    end

    # create :completed_game, :with_users_and_winner, users: [user1, user2, user3], user_won: user2
    trait :with_users_and_winner do
      transient do
        users { [] }
        user_won { nil }
      end

      after(:create) do |game, evaluator|
        game.player_count = evaluator.users.count
        evaluator.users.each do |user|
          player = create(:player, game: game, user: user)
          game.update!(winner: player) if user == evaluator.user_won
        end
        game.reload
      end
    end

    # create :game, :with_users, users: [user1, user2, user3]
    trait :with_users do
      transient do
        users { [] }
      end

      after(:create) do |game, evaluator|
        game.player_count = evaluator.users.count
        evaluator.users.each do |user|
          create(:player, game: game, user: user)
        end
        game.reload
      end
    end

    # create :started_game, users: [user1, user2], player_count: 2
    factory :started_game do
      transient do
        users { [] }
      end

      after(:create) do |game, evaluator|
        evaluator.users.each do |user|
          create(:player, game: game, user: user)
        end
        Game.find(game.id).start!
      end
    end
    factory :completed_game, traits: %i[started completed]

    # games in different states with players attached:
    # waiting game
    # full game
    # started game

    # create(:game_with_users, joined_users: [create :bob_user, create :jeff_user])

    # create(:game_with_players, joined_player_count: 2)
    # factory :game_with_players do
    #   transient do
    #     joined_player_count { 2 }
    #   end

    #   after(:create) do |game, evaluator|
    #     create_list(:player, evaluator.joined_player_count, game: game)

    #     # You may need to reload the record here, depending on your application
    #     game.reload
    #   end
    # end
  end
end
