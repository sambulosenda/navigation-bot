require 'faraday'
require 'json'


class GoogleClient

  # initialize
  def initialize(server_key)
    @server_key = server_key
  end

  # get_streetview
  def get_streetview(lat, lng, degree, width, height)
    uri_string = 'https://maps.googleapis.com/maps/api/streetview'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.get do |request|
      request.params['key'] = @server_key
      request.params['size'] = "#{width}x#{height}"
      request.params['location'] = "#{lat},#{lng}"
      request.params['fov'] = "#{degree}"
      request.params['heading'] = '0'
      request.params['pitch'] = '0'
      request.headers['Content-Type'] = 'application/json'
    end

    response.body
  end

  # get_directions
  def get_directions(origin_lat, origin_lng, destination_lat, destination_lng)
    uri_string = 'https://maps.googleapis.com/maps/api/directions/json'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.get do |request|
      request.params['key'] = @server_key
      request.params['origin'] = "#{origin_lat},#{origin_lng}"
      request.params['destination'] = "#{destination_lat},#{destination_lng}"
      request.params['mode'] = 'walking'
      request.headers['Content-Type'] = 'application/json'
    end

   JSON.parse(response.body)
  end

  # parse_get_directions_steps
  def parse_get_directions_steps(json)
    # no route
    routes = json['routes']
    return nil unless routes
    return nil unless routes.count

    # legs
    legs = routes.first['legs']
    return nil unless legs
    return nil unless legs.count

    # steps
    steps = legs.first['steps']
    return nil unless steps
    return nil unless steps.count

    steps
  end

  # get_geocode
  def get_geocode(address)
    uri_string = 'https://maps.googleapis.com/maps/api/geocode/json'
    connection = Faraday.new(:url => uri_string) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = connection.get do |request|
      request.params['key'] = @server_key
      request.params['address'] = address
      request.headers['Content-Type'] = 'application/json'
    end

   JSON.parse(response.body)
  end

  # parse_get_geocode
  def parse_get_geocode(json)
    results = json['results']
    return nil unless results
    return nil unless results.count

    return results.first
  end

end
