# frozen_string_literal: true

require_relative 'base'

module HoTan
  class Post
    module Type
      class Read < Base
        private

        def type_directory
          'reading'
        end
      end
    end
  end
end
