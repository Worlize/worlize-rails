class AdminController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  def index
    @user_count = User.count;
    @registration_count = Registration.count;
    @new_users_today = User.where(['created_at >= ?', 1.day.ago]).count
    @new_users_this_week = User.where(['created_at >= ?', 1.week.ago]).count
    @new_users_this_month = User.where(['created_at >= ?', 1.month.ago]).count
    
    data_points = User.connection.select_all(
        'select count(1) as signups, date_format(created_at, \'%Y-%m-%d\') as day from users WHERE created_at > NOW() - INTERVAL 3 MONTH GROUP BY day ORDER BY day;'
    )
    data_hash = {}
    data_points.each do |point|
      data_hash[point['day']] = point['signups']
    end
    new_users_by_day = []
    ((Date.today-2.months)..Date.today).each do |day|
      new_users_by_day.push([
        day.to_s,
        data_hash[day.to_s] || 0
      ])
    end
    @new_user_graph_data = Yajl::Encoder.encode(new_users_by_day)
  end

end
