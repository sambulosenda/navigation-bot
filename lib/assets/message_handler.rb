#require 'math'
require './lib/assets/google_client'
require './lib/assets/facebook_client'


class MessageHandler

  # initialize
  def initialize(facebook_id)
    @server_key = ENV['GOOGLE_API_KEY']
    @sender = Sender.find_by_facebook_id facebook_id
  end

  # post_error
  def post_error
    facebook_client = FacebookClient.new
    json = facebook_client.post_message(@sender.facebook_id, 'Sorry. I am not sure what you meant.')
  end


  # post_message
  def post_message(received_message)
    json = {}
    return json unless @sender

    case @sender.navigation_status
    when 0
      json = post_text('I will navigate you to Digital Garage. Where is your current location?')
      update_navigation_status
      json
    when 1
      # get geocode from message
      result = set_geocode(received_message)
      return post_error unless result
      # get current step for navigation
      start_lat = result['geometry']['location']['lat'].to_f
      start_lng = result['geometry']['location']['lng'].to_f
      set_directions(start_lat, start_lng)
      set_current_step
      current_step = get_current_step
      return post_error unless current_step
      # post bot message
      title = 'Are you here?'
      subtitle = result['address_components'].first['short_name']
      image_uri = (current_step.images && current_step.images.count > 0) ? current_step.images[0].uri : ''
      buttons = ['Yes', 'No', 'Stop navigation']
      json = post_elements(title, subtitle, image_uri, buttons)
    when 2
      # get current step for navigation
      current_step = get_current_step
      return post_error unless current_step
      # post bot message
      title = 'Go toward the direction.'
      subtitle = "#{current_step.html_instructions} #{current_step.distance_text} #{current_step.duration_text}" if current_step
      image_uri = (current_step.images && current_step.images.count > 0) ? current_step.images[0].uri : ''
      buttons = nil
      json = post_elements(title, subtitle, image_uri, buttons)
      title = 'Let me know when you get there.'
      subtitle = nil
      image_uri = (current_step.images && current_step.images.count >= 2) ? current_step.images[1].uri : ''
      buttons = ['I got there', 'Stop navigation']
      json = post_elements(title, subtitle, image_uri, buttons)
    when 3
      json = post_text('Congratulations! You got the destination.')
      @sender.destroy if @sender
      json
    else
      json
    end
  end

  # post text
  def post_text(message)
    text = "{ 'text' : '#{message}' }"
    facebook_client = FacebookClient.new
    json = facebook_client.post_message(@sender.facebook_id, text)
  end

  # post elements
  def post_elements(title, subtitle, image_uri, buttons)
    # make post json
    subtitle_text = ''
    subtitle_text = "'subtitle':'#{subtitle}'" if subtitle
    buttons_text = ''
    if buttons
      for i in 0...buttons.count
        buttons_text += "{ 'type':'postback', 'title':'#{buttons[i]}', 'payload':'#{buttons[i]}' }"
        buttons_text += ', ' unless i == buttons.count-1
      end
      buttons_text = "'buttons':[ #{buttons_text} ]"
    end
    subtitle_text += ', ' if subtitle_text != '' && buttons_text != ''
    message = "{ 'attachment':{ 'type':'template', 'payload':{ 'template_type':'generic', 'elements':[ { 'title':'#{title}', 'image_url':'#{image_uri}', #{subtitle_text}#{buttons_text} } ] } } }"

    # request
    facebook_client = FacebookClient.new
    json = facebook_client.post_message(@sender.facebook_id, message)
  end


  # handle_postback
  def handle_postback(message)
    case @sender.navigation_status
    when 0
      post_message(message)
    when 1
      if message == 'Yes'
        update_navigation_status
        post_message(message)
      elsif message == 'No'
        @sender = Sender.recreate(@sender.facebook_id)
        post_message(message)
      elsif message == 'Stop navigation'
        @sender = Sender.recreate(@sender.facebook_id)
        post_message(message)
      end
    when 2
      if message == 'I got there'
        set_current_step
        post_message(message)
      elsif message == 'Stop navigation'
        @sender = Sender.recreate(@sender.facebook_id)
        post_message(message)
      end
    when 3
      {}
    else
      {}
    end
  end


  # update navigation status
  def update_navigation_status
    case @sender.navigation_status
    when 0
      @sender.navigation_status += 1
      @sender.save if @sender.valid?
    when 1
      @sender.navigation_status += 1
      @sender.save if @sender.valid?
    when 2
      @sender.navigation_status += 1
      @sender.save if @sender.valid?
    when 3
    else
      nil
    end
  end

  # set_directions
  def set_directions(start_lat, start_lng)
    # no sender
    return [] unless @sender

    # direction (steps for DG)
    dg_lat = 37.7868614
    dg_lng = -122.4036958
    google_client = GoogleClient.new(@server_key)
    json = google_client.get_directions(start_lat, start_lng, dg_lat, dg_lng)
    json_steps = google_client.parse_get_directions_steps(json)
    json_steps.each do |json_step|
      step = Step.new
      step.sender_id = @sender.id
      step.start_lat = json_step['start_location']['lat'].to_f
      step.start_lng = json_step['start_location']['lng'].to_f
      step.end_lat = json_step['end_location']['lat'].to_f
      step.end_lng = json_step['end_location']['lng'].to_f
      step.distance_text = json_step['distance']['text']
      step.duration_text = json_step['duration']['text']
      step.html_instructions = json_step['html_instructions']
      step.travel_mode = json_step['travel_mode']
      if step.valid?
        step.save
        @sender.steps << step
      end
    end

    @sender.save if @sender.valid?
    @sender.steps
  end

  # set_geocode
  def set_geocode(address)
    google_client = GoogleClient.new(@server_key)
    json = google_client.get_geocode(address)
    result = google_client.parse_get_geocode(json)
  end

  # set_streetview
  def set_streetview
    # current step
    current_step = get_current_step
    return unless current_step
    return if current_step.images.count >= 2

    # nearby photo or upload streetview images of start & end coordinates
    google_client = GoogleClient.new(@server_key)
    coordinates = [ {:lat => current_step.start_lat, :lng => current_step.start_lng}, {:lat => current_step.end_lat, :lng => current_step.end_lng} ]
    width = 320; height = 160; fov = 120; heading = Math.atan2((current_step.end_lat - current_step.start_lat), (current_step.end_lng - current_step.start_lng) * 2.0) * 180.0 / Math::PI
    types = ['atm', 'bus_station', 'car_dealer', 'car_rental', 'car_repair', 'car_wash', 'convenience_store', 'fire_station', 'gas_station', 'park', 'pharmacy', 'police', 'school', 'university']
    coordinates.each_with_index do |coordinate, index|
      # get image binary from street view
      lat = coordinate[:lat]
      lng = coordinate[:lng]

      image_file = nil

      # nearby photo
      if index == coordinates.count-1
        json = google_client.get_place_nearbysearch_with_types(lat, lng, types)
        next unless json
        photo_reference = google_client.parse_get_place_nearbysearch(json)
        image_file = google_client.get_place_photo(photo_reference) if photo_reference
      end
      # street view
      image_file = google_client.get_streetview(lat, lng, fov, heading, width, height) unless image_file
      next unless image_file

      name = "#{lat}_#{lng}"

      # uploading image file
      temp_img_file = Tempfile.new("#{name}.jpeg")
      temp_img_file.binmode
      temp_img_file << image_file
      temp_img_file.rewind
      img_params = {:filename => "#{name}.jpeg", :type => 'image/jpeg', :tempfile => temp_img_file}

      # create image
      image = Image.new
      image.uri = ActionDispatch::Http::UploadedFile.new(img_params)
      image.name = name
      image.width = width
      image.height = height
      image.step_id = current_step.id

      if image.valid?
        image.save
        current_step.images << image
      end
    end

    current_step.save if current_step.valid?
  end

  # set current step
  def set_current_step
    return false unless @sender
    return false unless @sender.steps

    unless @sender.current_step_id
      @sender.current_step_id = @sender.steps.first.id
      @sender.save if @sender.valid?
    else
      index = nil
      for i in 0...@sender.steps.count
        index = i+1 and break if "#{@sender.steps[i].id}" == @sender.current_step_id
      end

      if index == nil
        @sender.current_step_id = @sender.steps.last.id
      elsif index >= @sender.steps.count
        update_navigation_status
      else
        @sender.current_step_id = @sender.steps[index].id
      end
      @sender.save if @sender.valid?
    end
    set_streetview

    true
  end

  # get current step
  def get_current_step
    return nil unless @sender
    return nil unless @sender.current_step_id
    Step.find_by_id(@sender.current_step_id)
  end

end
