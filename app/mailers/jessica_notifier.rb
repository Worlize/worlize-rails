class JessicaNotifier < ActionMailer::Base
  default :from => "Worlize <beta@worlize.com>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.actionmailer.notifier.beta_full_email.subject
  #
  def beta_full_email(registration)
    @registration = registration
    mail :to => 'jessica@worlize.com, brian@worlize.com, greg@worlize.com', :subject => 'New Worlize Registration'
  end
  
  def beta_code_signup(user)
    @user = user
    mail :to => 'jessica@worlid.com, brian@worlize.com, greg@worlize.com', :subject => "#{user.beta_code.code} Code Signup"
  end
end
