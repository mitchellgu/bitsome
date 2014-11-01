class StaticPagesController < ApplicationController
	def homepage
		redirect_to dashboard_show_path if user_signed_in?
	end
end
