class FlagInvalidUsernames < ActiveRecord::Migration
  def up
    execute <<-eof
    UPDATE `users`
      SET `state` = 'username_invalid'
      WHERE
        `username` REGEXP '(^.* +$|^ +.*$)' OR
        `username` REGEXP '(asshole|shit|fuck|cunt|nigger|nigga|wetback|fag|tranny|trany|dyke|cocksucker|bitch|pussy|piss|whore|douche|douchy|douchey|slut)'
    eof
  end
  def down
    execute "UPDATE `users` SET `state` = 'user_ready' WHERE `state` = 'username_invalid'"
  end
end
