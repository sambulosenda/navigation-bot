require 'faraday'
require 'json'


class FacebookClient

  # initialize
  def initialize()
    @access_token = ENV['FB_ACCESS_TOKEN']
  end

  # post_message
  def post_message(sender_id, text)
    uri_string = 'https://graph.facebook.com/v2.6/me/messages'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.post do |request|
      request.params['access_token'] = @access_token
      request.headers['Content-Type'] = 'application/json'
      request.body = "{ 'recipient' : { 'id' : '#{sender_id}' }, 'message' : #{text} }"
    end

    JSON.parse(response.body)
  end

end
