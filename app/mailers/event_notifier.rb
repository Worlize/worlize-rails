class EventNotifier < ActionMailer::Base
  default :from => "Worlize <noreply@worlize.com>"
  
  def new_friend_request_email(options)
    @sender = options[:sender]
    @recipient = options[:recipient]
    mail :to => @recipient.email,
         :subject => "#{@sender.username} sent you a friend request!"
  end
  
  def new_gift_email(options)
    @gift_name_map = {
      'Avatar' => 'Avatar',
      'InWorldObject' => 'Object',
      'Background' => 'Background',
      'Prop' => 'Prop'
    }
    @sender = options[:sender]
    @recipient = options[:recipient]
    @gift = options[:gift]
    mail :to => @recipient.email,
         :subject => "#{@sender.username} sent you a new #{@gift.giftable_type.downcase}!"
  end
  
  # def beta_invitation_email(options)
  #   @invitation = options[:beta_invitation]
  #   @account_creation_url = options[:account_creation_url]
  #   @inviter = options[:inviter]
  #   mail :to => @invitation.email, :subject => "#{@inviter.username.capitalize} has invited you to Worlize Beta!"    
  # end
end
