# frozen_string_literal: true

require 'fileutils'

module HoTan
  class Post
    class DataFile
      class NotFoundError < StandardError; end

      attr_reader :path

      def initialize(path)
        @path = path
      end

      def read
        raise NotFoundError unless File.exist?(path)

        JSON.parse(File.read(path))
      end

      def save(data)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.pretty_generate(data))
      end

      def delete!
        FileUtils.rm path
      end
    end
  end
end
