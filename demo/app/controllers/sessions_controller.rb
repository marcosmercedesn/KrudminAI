class SessionsController < ApplicationController
  def new
    @users = DemoUser.order(:tenant, :name)
  end

  def create
    user = DemoUser.find_by(id: params[:demo_user_id])
    return redirect_to new_session_path, alert: "Choose a demo account." unless user

    session[:demo_user_id] = user.id
    redirect_to tickets_path, notice: "Signed in as #{user.name} for #{user.tenant}."
  end

  def destroy
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end