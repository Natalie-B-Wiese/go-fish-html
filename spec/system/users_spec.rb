require 'rails_helper'
RSpec.describe 'Users', type: :system do
  # TODO: refactor it so it only checks for errors on non valid
  # these specific validation other methods should go in the model spec
  context '/new' do
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
      it 'creates a user' do
        expect do
          fill_in "Email", with: 'Natalie'
          fill_in "Password", with: '123'
          fill_in "Re-enter Password", with: '123'
          click_button 'Create Account'
        end.to change(User, :count).by 1
      end

      it 'reroutes to games page' do
        fill_in "Email", with: 'Natalie'
        fill_in "Password", with: '123'
        fill_in "Re-enter Password", with: '123'
        click_button 'Create Account'
        expect(page).to have_current_path root_path
      end
    end

    context 'when user is invalid' do
      it 'does not create a user' do
        expect do
          fill_in "Email", with: 'Natalie'
          fill_in "Password", with: '123'
          fill_in "Re-enter Password", with: 'abc'
          click_button 'Create Account'
        end.to change(User, :count).by 0
      end

      it 'stays on same page' do
        fill_in "Email", with: 'Natalie'
        fill_in "Password", with: '123'
        fill_in "Re-enter Password", with: 'abc'
        click_button 'Create Account'
        expect(page.current_path).to eq new_user_path
      end

    end
  end
    

end