class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def create
    @user=User.new(user_params)
    if @user.save
      start_new_session_for(@user)
      redirect_to root_path
    else
      flash.now[:alert]="There was a problem signing up."
      render :new, layout: 'application_no_sidebar', status: :unprocessable_content
    end
  end

  def new
    @user=User.new
    render layout: 'application_no_sidebar'
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end