# frozen_string_literal: true

require_relative 'base'

module HoTan
  class Post
    module Type
      class Scrobble < Base
        private

        def type_slug
          [
            properties['scrobble-of'][0]['properties'].fetch_values('artist', 'title'),
            Time.parse(properties['published'][0]).strftime('%H%M%S')
          ].flatten.join('-').to_slug.normalize.to_s
        end
      end
    end
  end
end
