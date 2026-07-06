class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
    render layout: 'application_form'
  end

  def create
    if user = User.authenticate_by(params.require(:session).permit(:email_address, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      # render
      flash.now[:alert]= "Try another email address or password."
      render :new, layout: 'application_form', status: :unprocessable_content
      #redirect_to new_session_path, 
    end
  end
  # params.require(:user).permit(:email_address, :password, :password_confirmation)

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end
end
