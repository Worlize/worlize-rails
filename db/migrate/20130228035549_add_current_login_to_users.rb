class AddCurrentLoginToUsers < ActiveRecord::Migration
  def up
    execute <<-eof
      ALTER TABLE `users`
        ADD COLUMN `current_login_at` DATETIME AFTER `perishable_token`,
        ADD COLUMN `current_login_ip` VARCHAR(15) AFTER `last_login_at`
    eof
  end
  
  def down
    execute <<-eof
      ALTER TABLE `users`
        DROP COLUMN `current_login_at`,
        DROP COLUMN `current_login_ip`
    eof
  end
end
