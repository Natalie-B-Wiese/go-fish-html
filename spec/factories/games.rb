FactoryBot.define do
  factory :game do
    name {'Game 1'}
    state { 0 }
    player_count { 2 }
    min_players { 1 }
    max_players { 5 }
    started_at { "2026-07-01 14:23:43" }
    ended_at { nil }
  end
end
