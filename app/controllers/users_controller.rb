class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def create
    # TODO: do stuff here to create a user
    user=User.new(params.permit(:email_address, :password, :password_confirmation))
    if user.save
      start_new_session_for(user)
      redirect_to root_path
    else
      redirect_to new_user_path, alert: "There was a problem signing up."
    end
  end

  def new
    render layout: 'application_no_sidebar'
  end
end