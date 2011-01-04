class PublicWorldsController < ApplicationController
  def index
    worlds = PublicWorld.all.map { |public_world| public_world.world }
    
    render :json => Yajl::Encoder.encode({
      :success => true,
      :count => worlds.length,
      :data => worlds.map do |world|
        {
          :name => world.name,
          :guid => world.guid,
          :population => world.population
        }
      end
    })    
  end
end
