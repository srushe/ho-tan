# frozen_string_literal: true

require 'addressable'

module HoTan
  class Post
    class Location
      attr_reader :destination

      def initialize(destination)
        @destination = destination
      end

      def url_for_instance(instance)
        Addressable::URI.join(destination.base_url, "#{instance.path}/", instance.slug).to_s
      end

      def path_for_instance(instance)
        File.join(destination.directory, instance.path, "#{instance.slug}.json")
      end

      def path_for_url(url)
        uri = URI(url)
        File.join(destination.directory, path_from(uri), file_from(uri))
      end

      private

      def path_from(uri)
        Pathname.new(uri.path.to_s).dirname.to_s
      end

      def file_from(uri)
        "#{File.basename(uri.path, '.*')}.json"
      end
    end
  end
end
