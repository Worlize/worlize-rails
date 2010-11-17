class JessicaNotifier < ActionMailer::Base
  default :from => "Worlize <beta@worlize.com>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.actionmailer.notifier.beta_full_email.subject
  #
  def beta_full_email(registration)
    @registration = registration
    mail :to => 'jessica@worlize.com, brian@worlize.com', :subject => 'New Worlize Registration'
  end
end
