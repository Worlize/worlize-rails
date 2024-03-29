class AdminController < ApplicationController
  layout 'admin'
  
  before_filter :require_global_moderator_permission

  def index
    @user_count = User.count;
    @registration_count = Registration.count;
    
    @new_users_this_week = User.where(
      "date(convert_tz(created_at, 'UTC', 'America/Los_Angeles')) >= date(convert_tz(now() - interval 1 week, 'UTC', 'America/Los_Angeles'))"
    ).count
    
    @new_users_this_month = User.where(
      "date(convert_tz(created_at, 'UTC', 'America/Los_Angeles')) >= date(convert_tz(now() - interval 1 month, 'UTC', 'America/Los_Angeles'))"
    ).count
    
    @new_users_today = User.where(
      "date(convert_tz(created_at, 'UTC', 'America/Los_Angeles')) >= date(convert_tz(now(), 'UTC', 'America/Los_Angeles'))"
    ).count
    
    User.connection.execute(<<-eof)
      SET @running_total := (
          SELECT COUNT(1)
          FROM users
          WHERE convert_tz(created_at, 'UTC', 'America/Los_Angeles') <= date(convert_tz(now() - interval 3 month, 'UTC', 'America/Los_Angeles'))
      );
    eof
    query = <<-eof
      SELECT raw.day AS day, raw.signups AS signups,
             (@running_total := @running_total + raw.signups) AS running_total
       FROM
      (SELECT date(convert_tz(created_at, 'UTC', 'America/Los_Angeles')) AS day, count(1) AS signups
        FROM  users
        WHERE convert_tz(created_at, 'UTC', 'America/Los_Angeles') > date(convert_tz(now() - interval 3 month, 'UTC', 'America/Los_Angeles'))
        GROUP BY day
      ) AS raw;
    eof
    
    data_points = User.connection.select_all(query)
    
    data_hash = {}
    data_points.each do |point|
      data_hash[point['day'].to_s] = {
        :signups => point['signups'].to_i,
        :running_total => point['running_total'].to_i
      }
    end
    
    new_users_by_day = []
    found_start = false
    ((Date.today-3.months)..Date.yesterday).each do |day|
      day_string = day.to_s
      if !found_start && !data_hash[day_string]
        next
      end
      found_start = true
      new_users_by_day.push([
        day_string,
        data_hash[day_string] ? data_hash[day_string][:signups] : 0
      ])
    end
    @new_user_graph_data = Yajl::Encoder.encode(new_users_by_day)
    
    running_total = 0
    total_users_by_day = []
    found_start = false
    ((Date.today-3.months)..Date.yesterday).each do |day|
      if data_hash[day.to_s]
        found_start = true
        running_total = data_hash[day.to_s][:running_total]
      else
        next if !found_start
      end
      total_users_by_day.push([
        day.to_s,
        running_total
      ])
    end
    @user_count_by_day_data = Yajl::Encoder.encode(total_users_by_day)
  end

end