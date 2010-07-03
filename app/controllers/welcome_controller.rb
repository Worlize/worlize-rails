class WelcomeController < ApplicationController
  layout "prelaunch"
  def index
    @registration = Registration.new
    @developerRegistration = Registration.new
  end
end
