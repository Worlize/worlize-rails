class Notifier < ActionMailer::Base
  default :from => "Worlize <contact@worlize.com>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.actionmailer.notifier.beta_full_email.subject
  #
  def beta_full_email(registration)
    @registration = registration
    mail :to => registration.email, :subject => 'Aw, you just missed it!'
  end
  
  def password_reset_email(email, users)
    @users = users
    @reset_url_lookup = {}
    users.each do |user|
      @reset_url_lookup[user.id] = password_reset_url(user.perishable_token)
    end
    
    mail :to => email,
         :subject => 'Worlize Password Reset'
  end
end
