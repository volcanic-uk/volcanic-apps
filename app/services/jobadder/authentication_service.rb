require 'oauth2'
class Jobadder::AuthenticationService < BaseService

  class << self

    CREDENTIALS = {
        auth_url: 'https://id.jobadder.com/connect/authorize',
        access_token_url: 'https://id.jobadder.com/connect/token'
    }

    def client(jobadder_setting)

      @client = OAuth2::Client.new(
          jobadder_setting.ja_client_id,
          jobadder_setting.ja_client_secret,
          {authorize_url: CREDENTIALS[:auth_url],
           token_url: CREDENTIALS[:access_token_url]}
      )
      return @client
    rescue => e
      Rails.logger.info "--- jobadder client exception ----- : #{e.message}"
    end

    def authorize_url(callback_url, client)
      @callback_url = callback_url
      auth_url = client.auth_code.authorize_url({redirect_uri: @callback_url, access_type: 'offline', scope: 'read write offline_access'})
      @auth_url = URI.decode(auth_url)
    rescue => e
      Rails.logger.info "--- jobadder auth_url exception ----- : #{e.message}"
    end

    def get_access_token(authorization_code, client)
      begin
        @callback_url = callback_url
        @token = client.auth_code.get_token(authorization_code, :redirect_uri => @callback_url)

      rescue => e
        Rails.logger.info "--- jobadder get_access_token exception ----- : #{e.message}"
      end
    end

    def refresh_token(jobadder_setting)

      client = client(jobadder_setting)
      @response = OAuth2::AccessToken.from_hash(client, :refresh_token => jobadder_setting.refresh_token).refresh!

    rescue => e
      Rails.logger.info "--- jobadder refresh_token exception ----- : #{e.message}"

    end


    private

    def callback_url
      return Rails.env.development? ? 'http://127.0.0.1:3001/jobadder/callback' : "https://#{ENV['DOMAIN_NAME']}/jobadder/callback"
    end

  end

end