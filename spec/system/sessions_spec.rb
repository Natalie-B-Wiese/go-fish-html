require 'rails_helper'
RSpec.describe 'Sessions', type: :system do
  let(:user) {create(:user)}

  describe 'login ui' do
    before do
      visit new_session_path
    end

    it 'shows the login page' do
      expect(page).to have_content 'Log in'
      expect(page).to have_button 'Sign in'
    end

    context 'clicking on signup button' do
      before do
        click_on 'Create an account'
      end

      it 'sends it to signup page' do
        expect(page.current_path).to eq new_user_path
      end
    end

    context 'when clicked on forgot password' do
      before do
        click_on 'Forgot password?'
      end

      it 'sends them to forgot password page' do
        expect(page.current_path).to eq new_password_path
      end
    end

    
  end
  
  describe 'login flow' do
    before do
      visit new_session_path
    end

    context 'when user enters email and password that exists' do
      before do
        log_user_in(user)
      end

      it 'reroutes to game page' do
        expect(page.current_path).to eq(root_path) | eq(games_path)
      end
    end

    context 'when user entered invalid login info' do
      before do
        fill_in "Email", with: 'nonexistantemail@email.com'
        fill_in "Password", with: '123'
        click_button 'Sign in'
      end

      it 'shows an error message' do
        expect(page).to have_selector('.flash--alert')
      end

      it 'stays on login page' do
        expect(page.current_path).to eq(new_session_path) | eq(session_path)
      end
    end
  end

  describe 'logout flow' do
    before do
      log_user_in(user)
      visit root_path
      click_button 'Log Out'
    end

    it 'logs out and redirects' do
      expect(page.current_path).to eq new_session_path
      visit games_path
      expect(page.current_path).to eq new_session_path
    end

  end

end