require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'when passwords do not match' do
      it 'is not valid' do
        user=build(:user_incorrect_password)
        expect(user).to_not be_valid
      end
    end

    context 'when user with that email already exists' do
      it 'is not valid' do
        user1=create(:user1)
        sleep(1)
        user2=build(:user, email_address: user1.email_address)
        expect(user1).to be_valid
        expect(user2).to_not be_valid
      end
    end

    context 'when passwords match and user is unique' do
      it 'is valid' do
        user=build(:user)
        expect(user).to be_valid
      end
    end
  end
end
