
module SigninHelper
  def log_user_in(user)
    visit new_session_path
    fill_in "Email", with: user.email_address
    fill_in "Password", with: user.password
    click_button "Sign in"
  end

  def create_account(email:, password:, password_confirmation: password)
    visit new_user_path

    fill_in "Email", with: email
    fill_in "Password", with: password
    fill_in "Password confirmation", with: password_confirmation
    click_button 'Create Account'
  end

end
