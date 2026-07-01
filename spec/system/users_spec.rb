require 'rails_helper'
RSpec.describe 'Users', type: :system do
  context 'signup flow' do
    before do
      visit new_user_path
    end

    it 'shows the sign up page' do
      expect(page).to have_content 'Sign up'
      expect(page).to have_button 'Create Account'
      expect(page.current_path).to eq new_user_path
    end

    it 'allows user to enter an email, password, and confirmation password' do
      fill_in "Email", with: 'Natalie'
      fill_in "Password", with: '123'
      fill_in "Re-enter Password", with: '123'
    end

    context 'when user is valid' do
      it 'creates a user and reroutes to game page' do
        expect do
          fill_in "Email", with: 'Natalie'
          fill_in "Password", with: '123'
          fill_in "Re-enter Password", with: '123'
          click_button 'Create Account'
          expect(page).to have_current_path root_path
        end.to change(User, :count).by 1
      end
    end

    context 'when user is invalid' do
      it 'does not create a user and stays on same page and show error' do
        expect do
          fill_in "Email", with: 'Natalie'
          fill_in "Password", with: '123'
          fill_in "Re-enter Password", with: 'abc'
          click_button 'Create Account'
          expect(page).to have_selector('.flash--alert')
          expect(page.current_path).to eq new_user_path
        end.to change(User, :count).by 0
      end
    end
  end

  context 'show profile flow' do
    # Add a user profile page ( users#show ) that displays the logged-in user's info
    let(:user) {create(:user)}
  
    before do
      log_user_in(user)
      visit users_profile_path
    end

    it 'shows the user information' do
      expect(page.current_path).to eq users_profile_path
      expect(page).to have_content 'Profile'
      expect(page).to have_content user.email_address
    end
  end
    

end