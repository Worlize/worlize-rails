class WorldsController < ApplicationController
  
  def show
    world = World.find_by_guid(params[:id])
    if world
      owner = world.user
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => {
          :guid => world.guid,
          :name => world.name,
          :owner => {
            :name => owner.name,
            :username => owner.username,
            :guid => owner.guid
          },
          :rooms => world.rooms.map do |room|
            {
              :name => room.name,
              :guid => room.guid,
              :user_count => (rand * 15).round
            }
          end
        }
      })
    else
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "There is no such world."
      })
    end
  end
  
end
