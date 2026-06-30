require 'rails_helper'

RSpec.describe User, type: :model do
  let(:email) {'123@gmail.com'}
  let(:password) {'123'}

  describe 'validations' do
    context 'when passwords do not match' do
      it 'is not valid' do
        user=build(:user, email_address: email, password: password, password_confirmation: '0')
        expect(user).to_not be_valid
      end
    end

    context 'when user with that email already exists' do
      it 'is not valid' do
        user1=create(:user, email_address: email, password: password, password_confirmation: password)
        sleep(1)
        user2=build(:user, email_address: email, password: password, password_confirmation: password)
        expect(user1).to be_valid
        expect(user2).to_not be_valid
      end
    end

    context 'when passwords match and user is unique' do
      it 'is valid' do
        user=build(:user, email_address: email, password: password, password_confirmation: password)
        expect(user).to be_valid
      end
    end
  end
end
