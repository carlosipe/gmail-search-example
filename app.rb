require "cuba"
require "mote"
require "mote/render"
require 'signet/oauth_2/client'
require 'requests'
require 'json'
require 'open-uri'
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
      :scope => 'https://www.googleapis.com/auth/gmail.readonly',
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
    api  = API.new
    token = api.get_token(code)
    render 'form', token: token
  end

  on param('token'), param('words') do |token, words|
    words = URI::encode(words)
    url = "https://www.googleapis.com/gmail/v1/users/me/messages?alt=json&v=3.0&access_token=#{token}&q=#{words}"
    result = JSON.parse(Requests.request(:get, url).body)
    messages = result.fetch("messages")
    first_message = messages.first
    m = nil
    if first_message
      id = first_message.fetch("id")
      url = "https://www.googleapis.com/gmail/v1/users/me/messages/#{id}?alt=json&v=3.0&access_token=#{token}&format=full"
      m = JSON.parse(Requests.request(:get, url).body)
    end
    render 'result', result: m
  end

  on root do
    link = API.new.auth_link
    render 'index', link: link
  end
end