require 'rails_helper'

RSpec.describe Player, type: :model do
  let(:game) { create :game }
  let(:user) { create :user }

  it 'allows a player to join only once' do
    valid_player = build(:player, game:, user:)
    expect(valid_player).to be_valid
    valid_player.save

    invalid_player = build(:player, game:, user:)
    expect(invalid_player).to_not be_valid
    expect(invalid_player.errors.full_messages.to_sentence).to include('You already joined the game')
  end

  it 'does not allow a player to join a game that is already full' do
    full_game = create(:game, :with_users, player_count: 2, users: [create(:user1), create(:user2)])

    late_player = build(:player, game: full_game, user: create(:user3))

    expect(late_player).to_not be_valid
    expect(late_player.errors.full_messages.to_sentence).to include(Player::GAME_FULL_MESSAGE)
  end
end
