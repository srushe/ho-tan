# frozen_string_literal: true

require_relative 'base'

module HoTan
  class Post
    module Type
      class Article < Base
        private

        def type_slug
          return unless properties.key?('name') && properties['name'].is_a?(Array)

          properties['name'][0].to_slug.normalize.to_s
        end
      end
    end
  end
end
