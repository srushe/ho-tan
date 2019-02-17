# frozen_string_literal: true

require_relative 'base'

module HoTan
  class Post
    module Type
      class Reply < Base
        private

        def type_directory
          'replies'
        end
      end
    end
  end
end
