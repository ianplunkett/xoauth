module XOAuth
  class Configuration
    class << self 
      attr_accessor :oauth_token, :oauth_token_secret, :user
    end
  end
end
