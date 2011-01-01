class InWorld::YoutubePlayersController < ApplicationController
  def create
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    begin
      manager = room.room_definition.youtube_manager
      player = manager.create_new_player()
      render :json => Yajl::Encoder.encode({
        :success => true,
        :data => {
          :player => player
        }
      }) and return
    rescue => detail
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => detail.message
      }) and return
    end
  end
  
  def update
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    begin
      manager = room.room_definition.youtube_manager
      if params[:x] && params[:y] && params[:width] && params[:height]
        manager.move_player(params[:id], params[:x], params[:y], params[:width], params[:height])
      end
      if params[:data]
        data = (params[:data] != 'null') ? params[:data] : nil
        if !data.nil?
          begin
            data = Yajl::Parser.parse(data)
          rescue
            data = nil
          end
        end
        manager.update_player_data(params[:id], data)
      end
      render :json => Yajl::Encoder.encode({
        :success => true
      }) and return
    rescue => detail
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => detail.message
      }) and return
    end
    
  end
  
  def destroy
    room = Room.find_by_guid(params[:room_id])
    if !current_user.can_edit?(room)
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => "You do not have permisson to author this room"
      }) and return
    end
    
    begin
      manager = room.room_definition.youtube_manager
      manager.remove_player(params[:id])
      render :json => Yajl::Encoder.encode({
        :success => true
      }) and return
    rescue => detail
      render :json => Yajl::Encoder.encode({
        :success => false,
        :description => detail.message
      }) and return
    end
    
  end
end
