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
      create_account(email: 'natalie@example.com', password: '123')
    end

    context 'when user is valid' do
      it 'creates a user and reroutes to game page' do
        expect do
          create_account(email: 'natalie@example.com', password: '123')
          expect(page).to have_current_path root_path
        end.to change(User, :count).by 1
      end
    end

    context 'when user is invalid' do
      it 'does not create a user and stays on same page and show error' do
        expect do
          create_account(email: 'natalie@example.com', password: '123', password_confirmation: 'abc')
          expect(page).to have_selector('.flash--alert')
          # expect(page.current_path).to eq new_user_path
        end.to change(User, :count).by 0
      end

      context 'when the email is already taken' do
        it 'shows the user the error' do
          existing_user = create(:user)
          create_account(email: existing_user.email_address, password: '123')
          expect(page).to have_content 'exists'
        end
      end
    end
  end

  context 'show profile flow' do
    # Add a user profile page ( users#show ) that displays the logged-in user's info
    let!(:user) { create(:user) }

    before do
      sign_in_as(user)
      visit users_profile_path
    end

    it 'shows the user information' do
      expect(page.current_path).to eq users_profile_path
      expect(page).to have_content 'Profile'
      expect(page).to have_content user.email_address
    end

    it 'clicking edit button takes it to an edit page' do
      page.click_on 'Edit'
      expect(page.current_path).to eq edit_user_path(user)
    end
  end

  context 'edit profile' do
    let!(:user) { create(:user) }

    before do
      sign_in_as(user)
      visit edit_user_path(user)
    end

    it 'shows the edit page' do
      expect(page).to have_content 'Edit Profile'
      expect(page).to have_button 'Save'
    end

    it 'has the user information in the fields' do
      expect(page).to have_field('Email address', with: user.email_address)
      expect(page).to have_field('Name', with: user.name)
    end

    it 'allows user to change their email to a valid email' do
      new_email = 'email2@example.com'
      fill_in 'Email address', with: new_email
      click_button 'Save'
      user.reload
      expect(user.email_address).to eq new_email
      expect(page.current_path).to eq users_profile_path
    end

    it 'allows user to choose a country and state' do
      select 'United States', from: 'Country'

      click_button 'Save'
      user.reload
      expect(user.country).to eq 'US'
    end

    xit 'allows user to choose a state' do
      select 'United States', from: 'Country'
      select 'North Carolina', from: 'State'

      click_button 'Save'
      user.reload
      expect(page.state).to eq 'NC'
    end

    # TODO: add check to make sure new email is unique?

    it 'allows user to change their name to a valid name' do
      new_name = 'Jeff Jefferson'
      fill_in 'Name', with: new_name
      click_button 'Save'
      user.reload
      expect(user.name).to eq new_name
      expect(page.current_path).to eq users_profile_path
    end
  end
end
