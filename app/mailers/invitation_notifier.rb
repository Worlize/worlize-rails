class InvitationNotifier < ActionMailer::Base
  default :from => "beta@worlize.com"
  
  def beta_accepted_email(options)
    @invitation = options[:beta_invitation]
    @account_creation_url = options[:account_creation_url]
    mail :to => @invitation.email, :subject => 'You\'ve been accepted into the beta!'
  end
end
