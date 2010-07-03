class UsersController < ApplicationController
  
  def new
    @user = User.new
  end

  def create
    p params[:user]
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Registration Successful."
      redirect_to worlds_url
    else
      render :action => :new  
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user."
      redirect_to root_url
    else
      render :action => :edit
    end
  end

  def show
    @user = User.find(params[:id])
  end

end
