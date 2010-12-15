class InvitationNotifier < ActionMailer::Base
  default :from => "beta@worlize.com"
  
  def beta_accepted_email(options)
    @invitation = options[:beta_invitation]
    @account_creation_url = options[:account_creation_url]
    mail :to => @invitation.email, :subject => 'You\'ve been accepted into the beta!'
  end
  
  def beta_invitation_email(options)
    @invitation = options[:beta_invitation]
    @account_creation_url = options[:account_creation_url]
    @inviter = options[:inviter]
    mail :to => @invitation.email, :subject => "#{@inviter.username.capitalize} has invited you to Worlize Beta!"    
  end
  
end
