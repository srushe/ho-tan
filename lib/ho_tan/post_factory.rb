# frozen_string_literal: true

require_relative 'post'
require_relative 'post/location'
require_relative 'post/normalize'

module HoTan
  class PostFactory
    class InvalidPathError < StandardError; end
    class UnrecognisedDestinationError < StandardError; end

    attr_reader :destinations

    def initialize(destinations:)
      @destinations = destinations
    end

    def create(data)
      create_data = HoTan::Post::Normalize.for_create(data)
      destination = destination_from_data(create_data)
      HoTan::Post.create!(create_data, destination)
    end

    def from(url)
      destination = destination_from_url(url)
      path = HoTan::Post::Location.new(destination).path_for_url(url)
      HoTan::Post.retrieve(path, url, destination)
    rescue HoTan::Post::InvalidPathError
      raise InvalidPathError
    end

    private

    def destination_from_data(data)
      return destinations.default unless data['properties'].key?('mp-destination')

      destination = destinations.all.find do |d|
        d.uid == data['properties']['mp-destination'][0]
      end
      raise UnrecognisedDestinationError if destination.nil?

      data['properties'].delete('mp-destination')
      destination
    end

    def destination_from_url(url)
      destination = destinations.all.find do |d|
        url.start_with?(d.base_url)
      end
      raise UnrecognisedDestinationError if destination.nil?

      destination
    end
  end
end
