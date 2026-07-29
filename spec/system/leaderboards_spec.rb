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

  let(:expected_user1_row) { { user: user1, total_games: 5, games_won: 3, time_played: 50, win_percentage: 60.0 } }
  let(:expected_user2_row) { { user: user2, total_games: 5, games_won: 1, time_played: 50, win_percentage: 20.0 } }
  let(:expected_user3_row) { { user: user3, total_games: 3, games_won: 2, time_played: 30, win_percentage: 66.7 } }

  let(:expected_rows) do
    [
      expected_user1_row,
      expected_user2_row,
      expected_user3_row
    ]
  end

  before do
    sign_in_as(user1)
    visit leaderboards_path
  end

  it 'shows the leaderboard index' do
    expect(page).to have_content 'Total Games'
  end

  it 'shows user stats only for players with completed games and it ignores incomplete games' do
    rows = page.within('tbody') { find_all('tr') }
    expect(rows.count).to eq expected_rows.count
    expect(page).not_to have_content user4.name

    # ensures the rows are there and ignores ordering
    expected_rows.each do |expected|
      row = rows.find { |r| r.has_content?(expected[:user].name) }
      expect_row_stats(row, **expected.except(:user))
    end
  end

  it 'sorts ascending by total games when the sort button is clicked' do
    click_link 'Total Games'

    rows = page.within('tbody') { find_all('tr') }
    names = rows.map { |r| r.find_all('td').first.text }

    expect(names.first).to eq user3.name
    expect(names.last(2)).to contain_exactly(user1.name, user2.name)
  end

  it 'marks the clicked sort button as active and leaves the others inactive' do
    click_link 'Total Games'

    expect(page).to have_css('a.btn--active', text: 'Total Games')
    expect(page).to have_no_css('a.btn--active', text: 'Games Won')

    click_link 'Games Won'

    expect(page).to have_css('a.btn--active', text: 'Games Won')
    expect(page).to have_no_css('a.btn--active', text: 'Total Games')
  end

  def expect_row_stats(row, total_games:, games_won:, time_played:, win_percentage:)
    cells = row.find_all('td')
    expect(cells[1]).to have_content total_games
    expect(cells[2]).to have_content games_won
    expect(cells[3]).to have_content "#{time_played} min"
    expect(cells[4]).to have_content "#{win_percentage}%"
  end
end
