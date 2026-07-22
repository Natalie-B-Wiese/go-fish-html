require 'rails_helper'

RSpec.describe GamePresenter, type: :model do
  let(:user1) { create(:user1) }
  let(:user2) { create(:user2) }
  let(:game) { create(:game, :with_users, users: [user1, user2]) }
  let(:presenter) { described_class.new(game, user1) }

  describe '#user_names_by_id' do
    it 'maps every joined user id to their name' do
      expect(presenter.user_names_by_id).to eq(user1.id => user1.name, user2.id => user2.name)
    end
  end
end
