class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path
    else
      flash.now[:alert] = 'There was a problem signing up.'
      render :new, layout: 'application_form', status: :unprocessable_content
    end
  end

  def new
    @user = User.new
    render layout: 'application_form'
  end

  def edit
    @user = Current.user
  end

  def update
    @user = Current.user

    if @user.update!(user_params)
      redirect_to users_profile_path
    else
      # TODO: do stuff
    end
  end

  def turbo_fetch
    @user = User.new(params.require(:user).permit(:email_address, :name, :country, :state))
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :name, :password, :password_confirmation, :country, :state)
  end
end
