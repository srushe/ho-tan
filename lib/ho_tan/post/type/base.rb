# frozen_string_literal: true

require 'babosa'
require 'time'

module HoTan
  class Post
    module Type
      class Base
        attr_reader :data

        def initialize(data)
          @data = data
          @data['properties']['entry_type'] = [entry_type]
        end

        def path
          @path ||= File.join(type_directory, Time.parse(data['properties']['published'][0]).strftime('%Y/%m/%d'))
        end

        def slug
          @slug ||= mp_slug || type_slug || default_slug
        end

        def properties
          data['properties']
        end

        protected

        def entry_type
          self.class.to_s.split('::').last.downcase
        end

        def type_directory
          "#{entry_type}s"
        end

        def mp_slug
          return nil unless properties.key?('mp-slug') && properties['mp-slug'].is_a?(Array)

          slug = properties['mp-slug'][0].to_s.to_slug.normalize.to_s
          slug.empty? ? nil : slug
        end

        def type_slug
          nil
        end

        def default_slug
          datetime = if properties.key?('published') && properties['published'].is_a?(Array)
                       Time.parse(properties['published'][0])
                     else
                       Time.now.utc
                     end

          datetime.strftime('%H%M%S')
        end
      end
    end
  end
end
