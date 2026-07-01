FactoryBot.define do
  factory :game do
    name {'Game 1'}
    player_count { 2 }
    started_at { nil }
    ended_at { nil }
  end
end
