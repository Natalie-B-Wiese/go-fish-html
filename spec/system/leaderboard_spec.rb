require 'rails_helper'
RSpec.describe 'Leaderboard', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }
  let!(:user4) { create(:user4) }

  let!(:game1) do
    create :completed_game, :with_users_and_winner, name: 'Game 1', users: [user1, user2], user_won: user1,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end
  let!(:game2) do
    create :completed_game, :with_users_and_winner, name: 'Game 2', users: [user2, user1], user_won: user1,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end
  let!(:game3) do
    create :completed_game, :with_users_and_winner, name: 'Game 3', users: [user2, user3], user_won: user3,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end
  let!(:game4) do
    create :completed_game, :with_users_and_winner, name: 'Game 4', users: [user2, user1], user_won: user2,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end

  let!(:game5) do
    create :completed_game, :with_users_and_winner, name: 'Game 5', users: [user1, user2, user3], user_won: user3,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end

  let!(:game6) do
    create :completed_game, :with_users_and_winner, name: 'Game 6', users: [user1, user3], user_won: user1,
                                                    started_at: 10.minutes.ago, ended_at: Time.zone.now
  end

  let!(:unfinished_game) do
    create :game, :with_users, name: 'Game 7', users: [user1, user4], started_at: 5.minutes.ago
  end

  let(:expected_rows) do
    [
      { user: user1, total_games: 5, games_won: 3, time_played: 50, win_percentage: 60.0 },
      { user: user3, total_games: 3, games_won: 2, time_played: 30, win_percentage: 66.7 },
      { user: user2, total_games: 5, games_won: 1, time_played: 50, win_percentage: 20.0 }
    ]
  end

  before do
    sign_in_as(user1)
    visit pages_leaderboard_path
  end

  it 'shows finished game stats for all players, sorted by games won, and ignores incomplete games and users with no completed games' do
    rows = page.within('tbody') { find_all('tr') }
    expect(rows.count).to eq expected_rows.count
    expect(page).not_to have_content user4.name

    expected_rows.each_with_index do |expected, index|
      expect(rows[index]).to have_content expected[:user].name
      expect_row_stats(rows[index], **expected.except(:user))
    end
  end

  def expect_row_stats(row, total_games:, games_won:, time_played:, win_percentage:)
    cells = row.find_all('td')
    expect(cells[1]).to have_content total_games
    expect(cells[2]).to have_content games_won
    expect(cells[3]).to have_content "#{time_played} min"
    expect(cells[4]).to have_content "#{win_percentage}%"
  end
end
