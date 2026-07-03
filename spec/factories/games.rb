FactoryBot.define do
  factory :game do
    name {'Game 1'}
    player_count { 2 }
    started_at { nil }
    ended_at { nil }

    trait :started do
      started_at {Time.zone.now}
    end

    trait :completed do
      ended_at {Time.zone.now}
    end

    # create :game, :with_users, users: [user1, user2, user3]
    trait :with_users do
      transient do
        users {[]}
      end

      after(:create) do |game, evaluator|
        evaluator.users.each do |user|
          create(:player, game: game, user: user)
        end
        game.reload
      end
    end

    factory :started_game, traits: [:started]
    factory :completed_game, traits: [:started, :completed]

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
