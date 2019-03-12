# frozen_string_literal: true

require_relative 'post/data_file'
require_relative 'post/location'
require_relative 'post/type/article'
require_relative 'post/type/bookmark'
require_relative 'post/type/checkin'
require_relative 'post/type/like'
require_relative 'post/type/note'
require_relative 'post/type/photo'
require_relative 'post/type/read'
require_relative 'post/type/reply'
require_relative 'post/type/repost'
require_relative 'post/type/scrobble'

module HoTan
  class Post
    class DuplicateCreateError < StandardError; end
    class InvalidPathError < StandardError; end
    class InvalidUpdateError < StandardError; end
    class UnrecognisedTypeError < StandardError; end

    attr_reader :instance, :destination, :original_url

    def self.create!(data, destination)
      post = new(instance_from(data), destination)
      raise DuplicateCreateError if File.exist?(post.save_location)
      post.tap(&:save!)
      # new(instance_from(data), destination).tap(&:save!)
    end

    def self.retrieve(path, url, destination)
      data = HoTan::Post::DataFile.new(path).read
      new(instance_from(data), destination, original_url: url)
    rescue HoTan::Post::DataFile::NotFoundError
      raise InvalidPathError
    end

    def update!(data)
      if data.key?('replace')
        raise InvalidUpdateError unless data['replace'].is_a?(Hash)
        raise InvalidUpdateError unless data['replace'].values.all? { |v| v.is_a?(Array) }

        instance.properties.merge!(data['replace'])
      end
      if data.key?('add')
        raise InvalidUpdateError unless data['add'].is_a?(Hash)
        raise InvalidUpdateError unless data['add'].values.all? { |v| v.is_a?(Array) }

        data['add'].each_pair do |k, additions|
          instance.properties[k] ||= []
          instance.properties[k] += additions
        end
      end
      if data.key?('delete')
        raise InvalidUpdateError unless data['delete'].is_a?(Array) || data['delete'].is_a?(Hash)
        raise InvalidUpdateError if data['delete'].is_a?(Hash) && !data['delete'].values.all? { |v| v.is_a?(Array) }

        if data['delete'].is_a?(Array)
          data['delete'].each { |k| instance.properties.delete(k) }
        else
          data['delete'].each_pair do |k, removals|
            removals.each { |value| instance.properties[k].delete(value) }
            instance.properties.delete(k) if instance.properties[k].empty?
          end
        end
      end

      instance.properties['updated_at'] = [Time.now.utc.iso8601]

      save!

      delete_original if updated_url?
    end

    def delete!
      instance.properties['deleted_at'] = [Time.now.utc.iso8601]
      save!
    end

    def undelete!
      instance.properties.delete('deleted_at')
      save!
    end

    # Where should this post be saved?
    def save_location
      @save_location ||= location.path_for_instance(instance)
    end

    def absolute_url
      @absolute_url ||= location.url_for_instance(instance)
    end

    def updated_url?
      return false if original_url.nil?

      original_url != absolute_url
    end

    def save!
      HoTan::Post::DataFile.new(save_location).save(instance.data)
    end

    private

    def initialize(instance, destination, original_url: nil)
      @instance = instance
      @destination = destination
      @original_url = original_url
    end

    def location
      @location ||= HoTan::Post::Location.new(destination)
    end

    def delete_original
      path_for_original_url = location.path_for_url(original_url)
      HoTan::Post::DataFile.new(path_for_original_url).delete!
    end

    def self.instance_from(data)
      post_type = Indieweb::PostTypes.type_from(data)
      klass_for(post_type).new(data)
    end
    private_class_method :instance_from

    def self.klass_for(post_type)
      Object.const_get("HoTan::Post::Type::#{post_type.capitalize}")
    rescue NameError
      raise UnrecognisedTypeError, "The type '#{post_type}' is not recognised"
    end
    private_class_method :klass_for
  end
end
