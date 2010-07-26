class PreferencesController < ApplicationController
  before_filter :require_user

  def show
    redis = Worlize::RedisConnectionPool.get_client(:preferences)
    prefs = redis.get(current_user.guid)
    if prefs.nil?
      render :json => "{}"
    else
      render :json => prefs
    end
  end
  
  def update
    redis = Worlize::RedisConnectionPool.get_client(:preferences)
    begin
      new_prefs = Yajl::Parser.parse(params[:data])
      if new_prefs
        redis.set(current_user.guid, Yajl::Encoder.encode(new_prefs))
      end
      render :json => '{"success":true}' and return
    rescue
    end
    render :json => '{"success":false}'
  end
end
