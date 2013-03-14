class UpdateIndicesOnUsersTable < ActiveRecord::Migration
  def up
    
    def append_id(str, maxlen, id)
      n = id.to_s
      if (str.length + 1 + n.length > maxlen)
        result = String.new(str)
        result[(maxlen - 1 - n.length)..-1] = "-#{n}"
      else
        result = "#{str}-#{n}"
      end
      result
    end
    
    # Make sure all login_name values are unique
    results = exec_query <<-eof
      SELECT count(1) as count, login_name
        FROM users
        GROUP BY login_name
        HAVING count > 1
    eof
    results.to_a.each do |row|
      counter = 0
      User.where(:login_name => row['login_name']).order('id').each do |user|
        if (counter += 1) == 1
          puts "Skipping first record (#{user.id}) for login name #{user.login_name}"
          next
        end
        new_name = append_id(user.login_name, 50, user.id)
        puts "Updating login_name for record #{user.id} to #{new_name}"
        user.update_attribute(:login_name, "#{new_name}")
      end
    end
    
    # Make sure all username values are unique
    results = exec_query <<-eof
      SELECT count(1) as count, username
        FROM users
        GROUP BY username
        HAVING count > 1
    eof
    results.to_a.each do |row|
      counter = 0
      User.where(:username => row['username']).order('id').each do |user|
        if (counter += 1) == 1
          puts "Skipping first record (#{user.id}) for username #{user.username}"
          next
        end
        new_name = append_id(user.username, 36, user.id)
        puts "Updating username for record #{user.id} to #{new_name}"
        user.update_attribute(:username, "#{new_name}")
      end
    end
    
    remove_index :users, :login_name
    remove_index :users, :username
    add_index :users, :login_name, :unique => true
    add_index :users, :username, :unique => true
    add_index :users, :persistence_token, :unique => true
    add_index :users, :perishable_token, :unique => true
    add_index :users, :single_access_token, :unique => true
  end

  def down
    remove_index :users, :single_access_token
    remove_index :users, :perishable_token
    remove_index :users, :persistence_token
    remove_index :users, :username
    remove_index :users, :login_name
    add_index :users, :username, :unique => false
    add_index :users, :login_name, :unique => false
  end
end
