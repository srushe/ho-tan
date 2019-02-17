# frozen_string_literal: true

module HoTan
  class Post
    module Normalize
      class InvalidHError < StandardError; end
      class InvalidTypeError < StandardError; end
      class InvalidCreateError < StandardError; end

      class << self
        def for_create(params)
          if url_encoded_create?(params)
            url_encoded_create_data_from(params)
          elsif json_create?(params)
            json_create_data_from(params)
          else
            raise InvalidCreateError
          end
        end

        private

        def url_encoded_create?(data)
          return false unless data.key?('h')
          return true if data['h'] == 'entry'

          raise InvalidHError
        end

        def json_create?(data)
          return false unless data.key?('properties')
          return true if data.key?('type') && data['type'].is_a?(Array) && data['type'][0] == 'h-entry'

          raise InvalidTypeError
        end

        def url_encoded_create_data_from(data)
          create_data = {
            'type' => ["h-#{data['h']}"],
            'properties' => Hash[data.reject { |k, _v| k == 'h' }.map { |k, v| [k.to_s, Array(v)] }]
          }

          create_data['properties']['published'] ||= [Time.now.utc.iso8601]
          create_data
        end

        def json_create_data_from(data)
          create_data = {
            'type' => data['type'],
            'properties' => data['properties']
          }

          create_data['properties']['published'] ||= [Time.now.utc.iso8601]
          create_data
        end
      end
    end
  end
end
