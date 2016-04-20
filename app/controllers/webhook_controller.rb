require './lib/assets/message_handler'


class WebhookController < ApplicationController


  skip_before_filter :verify_authenticity_token


  def get_facebook
    verify_token = params['hub.verify_token']
    render text: 'no verify_token' and return unless verify_token == ENV['FB_VERIFY_TOKEN']
    challenge = params['hub.challenge']
    render text: 'no challenge' and return unless challenge

    render text: challenge
  end


  def post_facebook
    json = {}

    message = params['entry'][0]['messaging'][0]

    puts message

    # message
    if message.include?('message') && message['message']['text']
      facebook_id = message['sender']['id']
      sender = Sender.find_by_facebook_id facebook_id
      sender = Sender.recreate(facebook_id) unless sender
      text = message['message']['text']

      message_handler = MessageHandler.new(facebook_id)
      json = message_handler.post_message(text)

    # postback
    elsif message.include?('postback')
      facebook_id = message['sender']['id']
      sender = Sender.find_by_facebook_id facebook_id
      sender = Sender.recreate(facebook_id) unless sender
      text = message['postback']['payload']

      message_handler = MessageHandler.new(facebook_id)
      json = message_handler.handle_postback(text)
    end

    render json: json
  end


end
