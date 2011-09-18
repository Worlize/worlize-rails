class PublicWorldsController < ApplicationController
  before_filter :require_user
  
  def index
    public_worlds = PublicWorld.all.map { |public_world| public_world.world }
    
    worlds = public_worlds.map do |world|
      {
        :name => world.name,
        :guid => world.guid,
        :population => world.population,
        :entrance => world.rooms.first.guid
      }
    end
    
    my_world = current_user.worlds.first
    worlds.unshift({
      :name => 'My Worlz',
      :guid => my_world.guid,
      :population => my_world.population,
      :entrance => my_world.rooms.first.guid
    })
    
    render :json => {
      :success => true,
      :count => worlds.length,
      :data => worlds
    }
  end
end
