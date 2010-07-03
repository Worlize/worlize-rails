require 'test_helper'

class NotifierTest < ActionMailer::TestCase
  test "beta_full_email" do
    mail = Notifier.beta_full_email
    assert_equal "Beta full email", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
