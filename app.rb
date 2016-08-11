require "cuba"
require "mote"
require "mote/render"
require 'signet/oauth_2/client'
require 'requests'
Cuba.plugin(Mote::Render)

File.read(".env").scan(/(.*?)="?(.*)"?$/).each do |key, value|
  ENV[key] ||= value
end

class API
  def initialize
    @client = Signet::OAuth2::Client.new(
      :authorization_uri => 'https://accounts.google.com/o/oauth2/auth',
      :token_credential_uri =>  'https://www.googleapis.com/oauth2/v3/token',
      :client_id => ENV.fetch('GOOGLE_CLIENT_ID'),
      :client_secret => ENV.fetch('GOOGLE_CLIENT_SECRET'),
      :scope => 'https://www.googleapis.com/auth/contacts.readonly',
      :redirect_uri => ENV.fetch('REDIRECT_URI')
    ) 
  end

  def auth_link
    @client.authorization_uri
  end

  def get_token(code)
    @client.code=code
    tokens = @client.fetch_access_token!
    tokens.fetch('access_token')
  end
end

Cuba.define do
  on param('code') do |code|
    token = API.new.get_token(code)
    url = 'https://www.google.com/m8/feeds/contacts/default/full?alt=json&v=3.0&access_token=' + token
    require 'json'
    render 'result', entry: JSON.parse(Requests.request(:get, url).body).fetch('feed').fetch('entry')
  end

  on root do  
    link = API.new.auth_link
    render 'index', link: link
  end
end