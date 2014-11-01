class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def ensure_signed_in
  	unless signed_in?
  		flash[:notice] = "Sign in to view the dashboard"
  		redirect_to root_path
		end
	end
end
