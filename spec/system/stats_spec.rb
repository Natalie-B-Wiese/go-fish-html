require 'rails_helper'
RSpec.describe 'Stats', type: :system do
  let!(:user1) { create(:user1) }
  let!(:user2) { create(:user2) }
  let!(:user3) { create(:user3) }

  let!(:game1) { create :completed_game, :with_users_and_winner, name: 'Game 1', users: [ user1, user2 ], user_won: user1 }
  let!(:game2) { create :completed_game, :with_users_and_winner, name: 'Game 2', users: [ user2, user1 ], user_won: user1 }
  let!(:game3) { create :completed_game, :with_users_and_winner, name: 'Game 3', users: [ user1, user3 ], user_won: user1 }
  let!(:game4) { create :completed_game, :with_users_and_winner, name: 'Game 4', users: [ user2, user1 ], user_won: user2 }

  def switch_to_user(user)
    sign_out
    sign_in_as(user)
  end

  def expect_loss_win(loss:, win:)
    expect(page).to have_content "#{loss} loss"
    expect(page).to have_content "#{win} win"
  end

  before do
    sign_in_as(user1)
    visit stats_path
  end

  it 'shows the stats index' do
    visit stats_path
    expect(page).to have_content 'Stats'
  end

  it 'shows correct losses and wins' do
    expect_loss_win(loss: 1, win: 3)

    switch_to_user(user2)
    visit stats_path
    expect_loss_win(loss: 2, win: 1)

    switch_to_user(user3)
    visit stats_path
    expect_loss_win(loss: 1, win: 0)
  end

  it 'shows correct games played' do
    expect(page).to have_content '4'

    switch_to_user(user2)
    visit stats_path
    expect(page).to have_content '3'

    switch_to_user(user3)
    visit stats_path
    expect(page).to have_content '1'
  end
end
