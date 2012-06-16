require 'net/smtp'
require 'base64'
require 'cgi'
require 'openssl'

module XOAuth

  class OAuthEntity
    attr_accessor :key, :secret
    def initialize(key, secret)
      @key = key
      @secret = secret
    end
  end

  class Generator

    def initialize(nonce=nil, timestamp=nil)
      @nonce = nonce
      @timstamp = timestamp
      oauth_token = XOAuth::Configuration.oauth_token
      oauth_token_secret = XOAuth::Configuration.oauth_token_secret
      @user = XOAuth::Configuration.user

      @access_token = XOAuth::OAuthEntity.new(oauth_token, oauth_token_secret)
      @consumer = XOAuth::OAuthEntity.new('anonymous', 'anonymous')
      @protocol = 'smtp'
    end

    def Base64
      GenerateXOauthString() if @xoauth_request_string == nil
      Base64.encode64(@xoauth_request_string).gsub(/\n/,'')
    end

    def FormatParams(params, separator)
      param_fragments = []
      params.each do |k,v|
        v = CGI::escape(v)
        param_fragments.push("#{k}=#{v}")
      end
      sorted_params = param_fragments.sort
      sorted_params.join(separator)
    end

    def GenerateSignatureBaseString(method, request_url_base, params)
      EscapeAndJoin([method, request_url_base, FormatParams(params, '&')])
    end

    def EscapeAndJoin(list)
      list.map! do |i|
        CGI::escape(i)
      end
      joined_list = list.join('&')
    end

    def GenerateXOauthString
      method = 'GET'
      url_params = {}
      oauth_params = FillInCommonOauthParams(@consumer, @nonce, @timestamp)
      oauth_params['oauth_token'] = @access_token.key
      request_url_base = "https://mail.google.com/mail/b/#{@user}/#{@protocol}/"

      base_string = GenerateSignatureBaseString(method, request_url_base, oauth_params)
      signature = GenerateOauthSignature(base_string, @consumer.secret, @access_token.secret)
      oauth_params['oauth_signature'] = signature

      formatted_params = FormatParams(oauth_params,',')

      @xoauth_request_string = "#{method} #{request_url_base} #{formatted_params}"
    end

    def GenerateOauthSignature(base_string, consumer_secret, token_secret)
      key = EscapeAndJoin([consumer_secret, token_secret])
      GenerateHmacSha1Signature(base_string, key)
    end

    def GenerateHmacSha1Signature(text,key)
      Base64.encode64(OpenSSL::HMAC.digest('sha1', key, text)).gsub(/\n/,'')
    end

    def FillInCommonOauthParams(consumer, nonce=nil, timestamp=nil)
      params = Hash.new()
      params['oauth_consumer_key'] = consumer.key
      nonce = rand(2**64-1).to_s if nonce == nil
      timestamp = Time.now().to_i.to_s if timestamp == nil
      params['oauth_nonce'] = nonce
      params['oauth_signature_method'] = 'HMAC-SHA1'
      params['oauth_version'] = '1.0'
      params['oauth_timestamp'] = timestamp
      params
    end

    def GenerateRequestToken(consumer, scope, nonce, timestamp,google_accounts_url_generator)
      oauth_params = FillInCommonOauthParams(@consumer, @nonce, @timestamp)
      params['oauth_callback'] = 'oob'
      params['scope'] = scope

    end

    def GetAccessToken(consumer, request_token, oauth_verifier,google_accounts_url_generator)

    end
  end

end
