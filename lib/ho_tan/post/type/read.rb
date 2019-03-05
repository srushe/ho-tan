# frozen_string_literal: true

require_relative 'base'

module HoTan
  class Post
    module Type
      class Read < Base
        def path
          @path ||= File.join(type_directory, Time.parse(data['properties']['published'][0]).strftime('%Y/%m'))
        end

        private

        def type_slug
          properties['read-of'][0]['properties']['name'][0].split(':')[0].to_slug.normalize.to_s
        end

        def type_directory
          'reading'
        end
      end
    end
  end
end
