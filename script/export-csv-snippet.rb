require 'csv'
outfile = File.open("users.csv", "wb")
CSV::Writer.generate(outfile) do |csv|
  users = User.all
  users.each do |user|
    if !user.first_name.nil? && !user.last_name.nil?
      full_name = user.first_name + " " + user.last_name
    elsif user.facebook_authentication && !user.facebook_authentication.display_name.nil?
      full_name = user.facebook_authentication.display_name
    elsif user.twitter_authentication && !user.twitter_authentication.display_name.nil?
      full_name = user.twitter_authentication.display_name
    else
      full_name = "Worlize User"
    end

    csv << [full_name, user.username, user.email]
  end
end
outfile.close
