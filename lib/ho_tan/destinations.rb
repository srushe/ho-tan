# frozen_string_literal: true

require_relative 'destination'

module HoTan
  class Destinations
    attr_reader :destinations

    def self.from(data)
      new(data)
    end

    def all
      destinations
    end

    def to_config
      destinations.collect(&:to_config)
    end

    def default
      return @default_destination if defined? @default_destination

      @default_destination = destinations.find(&:default?) || destinations[0]
    end

    private

    def initialize(data)
      @destinations = data.collect do |destination_data|
        HoTan::Destination.new(destination_data)
      end
    end
  end
end
