Net::SMTP.class_eval do
  def capable_xoauth_auth?
    auth_capable?('XOAUTH')
  end
  

  def auth_xoauth(user, secret)
    check_auth_args user, secret
    res = critical {
      get_response('AUTH XOAUTH ' + secret)
    }
    check_auth_response res
    res
  end
end
