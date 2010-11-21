class Notifier < ActionMailer::Base
  default :from => "Worlize <beta@worlize.com>"

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.actionmailer.notifier.beta_full_email.subject
  #
  def beta_full_email(registration)
    @registration = registration
    mail :to => registration.email, :subject => 'Aw, you just missed it!'
  end
end
